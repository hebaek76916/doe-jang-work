# workstamp 💸

연봉 넣으면 **터미널에서 실시간으로 돈이 오른다.** 출근이 조금은 견딜 만해짐.

```
💸 +32,072원 [████████░░] 퇴근까지 1:52:12
```

의존성 0개, 파일 1개. 주말·한국 공휴일(대체공휴일 포함) 빼고 근무일 기준으로 계산.

## 설치

```bash
pip install workstamp        # (PyPI 배포 후)
# 지금은:
pip install git+https://github.com/<repo>.git#subdirectory=cli
# 또는 클론해서:
pip install ./cli
```

## 사용법

```bash
workstamp init --salary 5000        # 연봉 5,000만원, 근무 09:00–18:00(기본)
workstamp init --salary 5000 --start 10:00 --end 19:00

workstamp                            # 실시간 티커 (Ctrl+C로 종료)
workstamp stamp                      # 오늘 출근 도장 쾅 🔴
workstamp cal                        # 이번 달 도장 달력
workstamp --once                     # 한 줄만 출력하고 종료
workstamp --secret                   # 금액 끝 3자리만 (•••,072원) 🕶️
```

## tmux 상태바에 붙이기

```tmux
# ~/.tmux.conf
set -g status-interval 5
set -g status-right '#(workstamp --once --plain)'
```

## starship 프롬프트에 붙이기

```toml
# ~/.config/starship.toml
[custom.workstamp]
command = "workstamp --once --plain"
when = true
shell = "sh"
```

## 근무 단계

| 시간대 | 표시 |
|---|---|
| 출근 1시간 전 | 🏃 돈 벌러 가는 중 |
| 근무 중 | 💸 +32,072원 [████████░░] 퇴근까지 1:52:12 |
| 퇴근 직후 | 🍻 다 벌었다, 수고했다! |
| 퇴근 2시간 후에도 터미널 앞 | 🫠 무료봉사 중 |
| 주말·공휴일 | 🧘 무급 힐링 중 |

야근은 0원입니다. 정시에 카운팅이 멈춰요.

---

📱 iPhone 달력 도장 앱 / 🖥️ Mac 메뉴바 티커 버전도 있습니다.
