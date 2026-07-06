# 출근도장 💸

> 연봉을 입력하면 **오늘 하루 얼마 버는지 실시간으로 보여주는** 동기부여 앱.
> 출근 도장을 찍고, 일하는 동안 돈이 오르는 걸 지켜보세요.

| 플랫폼 | 형태 | 위치 |
|---|---|---|
| 🐍 **터미널 (CLI)** | `pip install` 한 방, 의존성 0 | [`cli/`](cli/) ← **여기부터 써보세요** |
| 🖥️ **macOS** | 메뉴바 티커 (초당 카운팅) | `MacSources/` |
| 📱 **iPhone** | 달력 도장 앱 + 홈 위젯 | `Sources/` |

## 뭐 하는 앱인가요

1. 연봉과 출퇴근 시각을 넣으면 **근무일 기준 일급**을 계산합니다 (주말·한국 공휴일 제외)
2. 근무 중엔 **초 단위로 돈이 올라갑니다** — `💸 +167,222원 [████████░░] 퇴근까지 1:33:55`
3. 퇴근하면 확정: "다 벌었다, 수고했다 🍻" / 야근하면: "무료봉사 중 🫠" (정시에 카운팅 멈춤)
4. 출근한 날마다 달력에 도장 쾅 🔴

## 빠른 시작 (CLI)

```bash
pip install ./cli
workstamp init --salary 5000    # 연봉 5,000만원
workstamp                       # 돈 오르는 거 구경
```

tmux 상태바·starship 연동 등 자세한 건 [cli/README.md](cli/README.md) 참고.

## 앱 빌드 (iOS / macOS)

Xcode 프로젝트는 [XcodeGen](https://github.com/yonaskolb/XcodeGen)으로 생성합니다:

```bash
brew install xcodegen
xcodegen generate
open WorkStamp.xcodeproj
```

- **iOS**: 스킴 `WorkStamp` → iPhone 시뮬레이터 (홈 위젯 포함)
- **macOS**: 스킴 `WorkStampMac` → My Mac (Dock 없는 메뉴바 전용 앱)

## 테마

키치 🎀 (Y2K 스티커) / 포멀 👔 (회사에서 안 튀게) / 매트릭스 🖥️ (터미널 감성) — 설정에서 전환.
**시크릿 모드 🕶️**를 켜면 금액 끝 3자리만 보여서 옆자리에 연봉을 들키지 않습니다.

## 문서

- [기획.md](기획.md) — 백로그, 마케팅 전략, 구현 프롬프트
