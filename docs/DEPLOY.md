# LandLearnApp 배포 안내

## 공개 URL (2가지)

| 방식 | 주소 | 폰에서 |
|------|------|--------|
| **GitHub Pages** | https://kahp82-svg.github.io/LandLearnApp/ | PC 없이 Safari 주소만 |
| **dothome** | https://kahp82.dothome.co.kr/app/ | 홈피와 같은 도메인 |

## 1. GitHub Pages (자동)

`main` 브랜치에 push하면 GitHub Actions가 배포합니다.

1. GitHub 저장소 → **Settings** → **Pages**
2. **Source**: GitHub Actions
3. push 후 1~3분 뒤 위 URL 확인

## 2. dothome (수동)

1. `업로드-dothome.bat` 실행
2. dothome FTP 비밀번호 입력
3. https://kahp82.dothome.co.kr/app/ 확인

## 3. 홈피 연결

ServerTest `learn.html` · `index.html` → `/app/` (또는 GitHub Pages) 링크
