[한국어](README.md) | [English](README.en.md) | [日本語](README.ja.md) | **简体中文**

# WorkStamp 💸（上班打卡）

> **输入年薪，上班时看着钱实时往上涨。**
> 亲眼看到今天赚了多少，上班就没那么难熬了 — 终端 · Mac 菜单栏 · iPhone。

```
💸 +167,222韩元 [████████░░] 距下班 1:33:55
```

按**实际工作日**（扣除周末和法定节假日）计算日薪，工作时间内每秒累加。
**加班 = 0 元** — 计数器到点就停 🫠（是的，白干连数字都懒得动）

> ⚠️ 目前仅支持韩国节假日和韩元(KRW)。
> 中国节假日（含调休！）与人民币支持在[路线图](기획.md)上。

## 截图

| 可爱风 🎀 | 黑客帝国 🖥️ |
|:---:|:---:|
| <img src="docs/screenshots/ios-kitsch.png" width="280"> | <img src="docs/screenshots/ios-matrix.png" width="280"> |
| <img src="docs/screenshots/mac-kitsch.png" width="360"> | <img src="docs/screenshots/mac-matrix.png" width="360"> |

*（以上 Mac 截图实际使用日语界面 — 切换地区会同时改变语言·货币·节假日）*

三套主题（可爱风／正式风／黑客帝国）＋ **隐身模式 🕶️** —
只显示金额末 3 位（`+•••,222`），旁边工位永远猜不到你的年薪。
末位数字一直在跳，"钱在涨"的快乐一点不少。

## 平台

| | 形态 | 安装 |
|---|---|---|
| 🐍 **CLI** | 终端计数器，零依赖·单文件 | `pipx install ./cli` → [用法](cli/README.md) |
| 🖥️ **macOS** | 菜单栏计数器（每秒刷新，无 Dock 图标） | 从 [Releases](../../releases) 下载 `.dmg` |
| 📱 **iOS** | 日历打卡 App + 桌面小组件 | 从源码构建（见下） |

## 快速开始 — CLI

```bash
brew install pipx && pipx ensurepath
git clone https://github.com/hebaek76916/doe-jang-work.git
pipx install ./doe-jang-work/cli

workstamp init --salary 5000   # 年薪（万韩元）
workstamp                      # 实时计数器
workstamp stamp                # 今日打卡 🔴
workstamp cal                  # 本月打卡日历
```

如何常驻 tmux 状态栏 / starship 提示符：[cli/README.md](cli/README.md)。

## 一天的节奏

| 时间段 | 显示 |
|---|---|
| 上班前 1 小时 | 🏃 搬砖路上 |
| 工作中 | 💸 +167,222韩元 [████████░░] 距下班 1:33:55 |
| 刚下班 | 🍻 赚满收工，辛苦了！ |
| 下班 2 小时还在工位 | 🫠 白干中 |
| 周末·节假日 | 🧘 0 元疗愈中 |

## 从源码构建（iOS / macOS）

Xcode 工程由 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成。

```bash
brew install xcodegen
xcodegen generate
open WorkStamp.xcodeproj
```

- **iOS**: scheme `WorkStamp` → iPhone 模拟器（iOS 17+，含桌面小组件）
- **macOS**: scheme `WorkStampMac` → My Mac（macOS 14+）

## 目录结构

```
Sources/          iOS App (SwiftUI)
Sources/Shared/   iOS·macOS 共用 — 日薪计算、工作日日历、主题、打卡存储
MacSources/       macOS 菜单栏 App (NSStatusItem + SwiftUI popover)
WidgetSources/    iOS 桌面小组件 (WidgetKit)
cli/              Python CLI（仅标准库）
```

## 路线图

下班推送、连续打卡 streak、分享卡片、"这些钱能买几杯奶茶"换算、
日语·中文本地化… 详情（韩语）：[기획.md](기획.md)

## 许可证

[MIT](LICENSE)
