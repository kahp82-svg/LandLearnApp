# LandLearnApp → dothome /html/app/ 업로드
# Usage: .\upload-to-dothome.ps1

param(
  [string]$RemoteSubDir = "app"
)

$ErrorActionPreference = "Stop"

$FtpHost = "kahp82.dothome.co.kr"
$FtpUser = "kahp82"
$RemoteDir = "/html/$RemoteSubDir"
$LocalDir = $PSScriptRoot

$excludeDirs = @(".git", ".github", ".cursor", "docs")
$excludeNames = @("upload-to-dothome.ps1", "serve-local.ps1")
$extensions = @(".html", ".css", ".js", ".webmanifest", ".bat", ".mdc")

function Get-UploadFiles {
  param([string]$Root)
  $items = @()
  Get-ChildItem -Path $Root -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($Root.Length + 1).Replace("\", "/")
    $parts = $rel -split "/"
    $skip = $false
    foreach ($part in $parts) {
      if ($excludeDirs -contains $part) { $skip = $true; break }
    }
    if ($skip) { return }
    if ($excludeNames -contains $_.Name) { return }
    if ($extensions -notcontains $_.Extension.ToLower()) { return }
    $items += [PSCustomObject]@{ File = $_; Rel = $rel }
  }
  return $items
}

if ($env:DOTHOME_FTP_PASS) {
  $FtpPass = $env:DOTHOME_FTP_PASS
} else {
  $secure = Read-Host "FTP password (dothome)" -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    $FtpPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) | Out-Null
  }
}

function New-FtpRequest {
  param([string]$RemotePath, [string]$Method, [bool]$Passive = $true)
  $uri = "ftp://${FtpHost}${RemotePath}"
  $request = [System.Net.FtpWebRequest]::Create($uri)
  $request.Method = $Method
  $request.Credentials = New-Object System.Net.NetworkCredential($FtpUser, $FtpPass)
  $request.UseBinary = $true
  $request.UsePassive = $Passive
  $request.KeepAlive = $false
  $request.Timeout = 120000
  return $request
}

function Ensure-FtpDirectory {
  param([string]$RemotePath)
  try {
    $req = New-FtpRequest -RemotePath $RemotePath -Method ([System.Net.WebRequestMethods+Ftp]::MakeDirectory)
    $res = $req.GetResponse()
    $res.Close()
  } catch {}
}

function Upload-FtpFile {
  param([string]$LocalPath, [string]$RemotePath)
  $bytes = [IO.File]::ReadAllBytes($LocalPath)
  $req = New-FtpRequest -RemotePath $RemotePath -Method ([System.Net.WebRequestMethods+Ftp]::UploadFile)
  $req.ContentLength = $bytes.Length
  $stream = $req.GetRequestStream()
  $stream.Write($bytes, 0, $bytes.Length)
  $stream.Close()
  $res = $req.GetResponse()
  $res.Close()
}

$files = Get-UploadFiles -Root $LocalDir
if ($files.Count -eq 0) {
  Write-Host "No files to upload." -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "=== LandLearnApp dothome upload ===" -ForegroundColor Cyan
Write-Host "Remote: https://${FtpHost}/${RemoteSubDir}/" -ForegroundColor Green
Write-Host "Files: $($files.Count)" -ForegroundColor Gray
Write-Host ""

Ensure-FtpDirectory -RemotePath $RemoteDir
$dirs = $files | ForEach-Object { Split-Path $_.Rel -Parent } | Where-Object { $_ } | Sort-Object -Unique
foreach ($d in $dirs) {
  $parts = $d -split "/"
  $acc = $RemoteDir
  foreach ($p in $parts) {
    $acc = "$acc/$p"
    Ensure-FtpDirectory -RemotePath $acc
  }
}

$ok = 0
$fail = 0
foreach ($item in $files) {
  $remote = "$RemoteDir/$($item.Rel)"
  try {
    Upload-FtpFile -LocalPath $item.File.FullName -RemotePath $remote
    Write-Host "[OK] $($item.Rel)" -ForegroundColor Green
    $ok++
  } catch {
    Write-Host "[FAIL] $($item.Rel) — $($_.Exception.Message)" -ForegroundColor Red
    $fail++
  }
}

Write-Host ""
Write-Host "Done: success $ok / fail $fail" -ForegroundColor Cyan
Write-Host "Phone URL: https://${FtpHost}/${RemoteSubDir}/" -ForegroundColor Green
