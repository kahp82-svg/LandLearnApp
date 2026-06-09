param(
  [int]$Port = 8770,
  [string]$Page = "index.html"
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot

function Test-PortListening {
  param([int]$Port)
  try {
    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    return ($null -ne $conn -and $conn.Count -gt 0)
  } catch {
    $out = netstat -ano | Select-String ":$Port\s"
    return ($null -ne $out)
  }
}

function Get-LanIPv4 {
  try {
    $configs = Get-NetIPConfiguration -ErrorAction SilentlyContinue |
      Where-Object { $_.NetAdapter.Status -eq 'Up' -and $null -ne $_.IPv4DefaultGateway }
    foreach ($cfg in $configs) {
      $ip = $cfg.IPv4Address.IPAddress
      if ($ip -and $ip -notlike '127.*' -and $ip -notlike '169.254.*') {
        return $ip
      }
    }
  } catch {}
  return $null
}

function Show-UsageInfo {
  param([int]$Port, [string]$Page, [string]$LanIp, [switch]$AlreadyRunning)

  Write-Host ""
  if ($AlreadyRunning) {
    Write-Host "이미 미리보기 서버가 켜져 있습니다." -ForegroundColor Yellow
    Write-Host "(bat을 또 실행하지 마세요 — 브라우저만 열면 됩니다)" -ForegroundColor Gray
  } else {
    Write-Host "LandLearnApp 미리보기" -ForegroundColor Cyan
  }
  Write-Host "  PC:  http://localhost:$Port/$Page" -ForegroundColor White
  if ($LanIp) {
    Write-Host "  폰:  http://${LanIp}:$Port/$Page" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [폰] 같은 Wi-Fi → 주소창에 '폰' 주소 입력" -ForegroundColor Gray
  } else {
    Write-Host ""
    Write-Host "  [폰] PC Chrome → F12 → 기기(📱) 모드" -ForegroundColor Gray
  }
  Write-Host ""
  Write-Host "서버 끄기: 검은 PowerShell 창에서 Ctrl+C" -ForegroundColor Gray
  Write-Host ""
}

# ── 포트가 이미 사용 중이면: 새 서버 안 띄우고 브라우저만 열기 ──
if (Test-PortListening -Port $Port) {
  $LanIp = Get-LanIPv4
  Show-UsageInfo -Port $Port -Page $Page -LanIp $LanIp -AlreadyRunning
  Start-Process "http://localhost:$Port/$Page"
  exit 0
}

function Start-LandLearnListener {
  param([int]$Port, [string]$LanIp, [switch]$LocalhostOnly)

  $listener = New-Object System.Net.HttpListener
  $listener.Prefixes.Add("http://localhost:$Port/")
  if ($LanIp -and -not $LocalhostOnly) {
    $listener.Prefixes.Add("http://${LanIp}:$Port/")
  }
  $listener.Start()
  return $listener
}

$LanIp = Get-LanIPv4
$listener = $null
$phoneUrlShown = $LanIp

try {
  $listener = Start-LandLearnListener -Port $Port -LanIp $LanIp
} catch {
  Write-Host ""
  Write-Host "LAN(폰) 주소 등록 실패 → PC(localhost)만 사용합니다." -ForegroundColor Yellow
  Write-Host ""
  $phoneUrlShown = $null
  $listener = Start-LandLearnListener -Port $Port -LanIp $null -LocalhostOnly
}

Show-UsageInfo -Port $Port -Page $Page -LanIp $phoneUrlShown
Write-Host "폴더: $Root" -ForegroundColor Gray
Write-Host "종료: Ctrl+C" -ForegroundColor Gray
Write-Host ""

Start-Process "http://localhost:$Port/$Page"

$mime = @{
  ".html" = "text/html; charset=utf-8"
  ".css"  = "text/css; charset=utf-8"
  ".js"   = "application/javascript; charset=utf-8"
}

try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()
    $path = $context.Request.Url.LocalPath.TrimStart("/")
    if ([string]::IsNullOrWhiteSpace($path)) { $path = "index.html" }
    $file = Join-Path $Root ($path -replace "/", [IO.Path]::DirectorySeparatorChar)

    if (-not (Test-Path $file -PathType Leaf)) {
      $context.Response.StatusCode = 404
      $bytes = [Text.Encoding]::UTF8.GetBytes("404 Not Found: $path")
      $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
      $context.Response.Close()
      continue
    }

    $ext = [IO.Path]::GetExtension($file).ToLower()
    $contentType = $mime[$ext]
    if (-not $contentType) { $contentType = "application/octet-stream" }

    $bytes = [IO.File]::ReadAllBytes($file)
    $context.Response.StatusCode = 200
    $context.Response.ContentType = $contentType
    $context.Response.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")
    $context.Response.ContentLength64 = $bytes.Length
    $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $context.Response.Close()
  }
} finally {
  $listener.Stop()
  $listener.Close()
}
