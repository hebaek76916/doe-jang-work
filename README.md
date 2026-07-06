**한국어** | [English](README.en.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md)

# 출근도장 💸 WorkStamp

> **연봉을 넣으면, 일하는 동안 돈이 실시간으로 오른다.**
> 오늘 하루 얼마 버는지 눈으로 보면서 출근을 견디는 앱 — 터미널·Mac 메뉴바·iPhone.

```
💸 +167,222원 [████████░░] 퇴근까지 1:33:55
```

주말·한국 공휴일(대체공휴일 포함)을 뺀 **근무일 기준**으로 일급을 계산하고,
근무시간 동안 초 단위로 카운팅합니다. **야근은 0원입니다** — 정시에 멈춰요 🫠

## 스크린샷

| 키치 🎀 | 매트릭스 🖥️ |
|:---:|:---:|
| <img src="docs/screenshots/ios-kitsch.png" width="280"> | <img src="docs/screenshots/ios-matrix.png" width="280"> |
| <img src="docs/screenshots/mac-kitsch.png" width="360"> | <img src="docs/screenshots/mac-matrix.png" width="360"> |

*(위 Mac 스크린샷은 일본어 로케일 예시입니다 — 국가를 바꾸면 언어·통화·공휴일이 통째로 전환됩니다)*

테마 3종(키치/포멀/매트릭스) + **시크릿 모드 🕶️** — 금액 끝 3자리만 표시해서
옆자리에 연봉을 들키지 않습니다 (`+•••,222원` — 끝자리는 계속 바뀌어서 오르는 재미는 그대로).

## 플랫폼

| | 형태 | 설치 |
|---|---|---|
| 🐍 **CLI** | 터미널 티커, 의존성 0·파일 1개 | `pipx install ./cli` → [사용법](cli/README.md) |
| 🖥️ **macOS** | 메뉴바 티커 (초당 카운팅, Dock 없음) | [Releases](../../releases)에서 `.dmg` → [설치방법](dist/설치방법.md) |
| 📱 **iOS** | 달력 도장 앱 + 홈 위젯 | 직접 빌드 (아래) |

## 빠른 시작 — CLI

```bash
brew install pipx && pipx ensurepath
git clone https://github.com/hebaek76916/doe-jang-work.git
pipx install ./doe-jang-work/cli

workstamp init --salary 5000   # 연봉 5,000만원 (만원 단위)
workstamp                      # 실시간 티커
workstamp stamp                # 오늘 출근 도장 쾅 🔴
workstamp cal                  # 이번 달 도장 달력
```

tmux 상태바·starship 프롬프트에 상주시키는 법은 [cli/README.md](cli/README.md)에.

## 하루의 흐름

| 시간대 | 표시 |
|---|---|
| 출근 1시간 전 | 🏃 돈 벌러 가는 중 |
| 근무 중 | 💸 +167,222원 [████████░░] 퇴근까지 1:33:55 |
| 퇴근 직후 | 🍻 다 벌었다, 수고했다! |
| 퇴근 2시간 후에도 화면 앞 | 🫠 무료봉사 중 |
| 주말·공휴일 | 🧘 무급 힐링 중 |

## 소스에서 빌드 (iOS / macOS)

Xcode 프로젝트는 [XcodeGen](https://github.com/yonaskolb/XcodeGen)으로 생성합니다.

```bash
brew install xcodegen
xcodegen generate
open WorkStamp.xcodeproj
```

- **iOS**: 스킴 `WorkStamp` → iPhone 시뮬레이터 (iOS 17+, 홈 위젯 포함)
- **macOS**: 스킴 `WorkStampMac` → My Mac (macOS 14+)
- Mac 배포용 `.dmg`는 `./scripts/build-mac-dmg.sh` 한 방

## 구조

```
Sources/          iOS 앱 (SwiftUI)
Sources/Shared/   iOS·macOS 공용 — 일급 계산, 근무일 캘린더, 테마, 도장 저장소
MacSources/       macOS 메뉴바 앱 (NSStatusItem + SwiftUI 팝오버)
WidgetSources/    iOS 홈 위젯 (WidgetKit)
cli/              Python CLI (표준 라이브러리만)
```

## 로드맵

퇴근 푸시, 연속 출근 스트릭, 공유 카드(짤), "이 돈이면 치킨 몇 마리" 환산,
일본·중국 로컬라이제이션… 자세한 건 [기획.md](기획.md).

## 라이선스

[MIT](LICENSE)
