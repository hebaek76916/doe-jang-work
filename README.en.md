[한국어](README.md) | **English** | [日本語](README.ja.md) | [简体中文](README.zh-CN.md)

# WorkStamp 💸

> **Enter your salary, and watch your money tick up in real time while you work.**
> A little motivation app that makes the workday bearable — in your terminal, Mac menu bar, and iPhone.

```
💸 +167,222 KRW [████████░░] 1:33:55 until clock-out
```

Your daily wage is calculated from **actual working days** (weekends and public
holidays excluded), and counts up second by second during work hours.
**Overtime earns you exactly 0** — the counter stops at quitting time 🫠

> ⚠️ Currently supports Korean public holidays and KRW only.
> Japanese/Chinese localization is on the [roadmap](기획.md).

## Screenshots

| Kitsch 🎀 | Matrix 🖥️ |
|:---:|:---:|
| <img src="docs/screenshots/ios-kitsch.png" width="280"> | <img src="docs/screenshots/ios-matrix.png" width="280"> |
| <img src="docs/screenshots/mac-kitsch.png" width="360"> | <img src="docs/screenshots/mac-matrix.png" width="360"> |

*(the Mac screenshots above are in Japanese — switching the region flips language, currency, and holidays all at once)*

Three themes (Kitsch / Formal / Matrix) + **Secret mode 🕶️** — shows only the
last 3 digits (`+•••,222`) so your coworkers can't figure out your salary.
The trailing digits keep changing, so the dopamine stays.

## Platforms

| | What it is | Install |
|---|---|---|
| 🐍 **CLI** | Terminal ticker, zero deps, single file | `pipx install ./cli` → [docs](cli/README.md) |
| 🖥️ **macOS** | Menu bar ticker (updates every second, no Dock icon) | `.dmg` from [Releases](../../releases) |
| 📱 **iOS** | Calendar stamp app + home widget | Build from source (below) |

## Quick start — CLI

```bash
brew install pipx && pipx ensurepath
git clone https://github.com/hebaek76916/doe-jang-work.git
pipx install ./doe-jang-work/cli

workstamp init --salary 5000   # annual salary in 만원 (10,000 KRW units)
workstamp                      # live ticker
workstamp stamp                # punch today's attendance stamp 🔴
workstamp cal                  # this month's stamp calendar
```

How to pin it to your tmux status bar or starship prompt: [cli/README.md](cli/README.md).

## A day in the life

| Time of day | Display |
|---|---|
| 1 hour before work | 🏃 Heading out to earn |
| During work | 💸 +167,222 KRW [████████░░] 1:33:55 left |
| Right after clock-out | 🍻 All earned. Well done! |
| Still at your desk 2h later | 🫠 Unpaid volunteering |
| Weekends & holidays | 🧘 Healing at 0 KRW/hour |

## Build from source (iOS / macOS)

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen generate
open WorkStamp.xcodeproj
```

- **iOS**: scheme `WorkStamp` → iPhone Simulator (iOS 17+, includes home widget)
- **macOS**: scheme `WorkStampMac` → My Mac (macOS 14+)

## Project layout

```
Sources/          iOS app (SwiftUI)
Sources/Shared/   Shared iOS·macOS — wage math, working-day calendar, themes, stamp store
MacSources/       macOS menu bar app (NSStatusItem + SwiftUI popover)
WidgetSources/    iOS home widget (WidgetKit)
cli/              Python CLI (stdlib only)
```

## Roadmap

Clock-out push notifications, attendance streaks, shareable cards,
"how many fried chickens is this?" conversion, JP/CN localization…
Details (in Korean): [기획.md](기획.md).

## License

[MIT](LICENSE)
