[한국어](README.md) | [English](README.en.md) | **日本語** | [简体中文](README.zh-CN.md)

# WorkStamp 💸（出勤ハンコ）

> **年収を入れると、働いている間にお金がリアルタイムで増えていく。**
> 今日いくら稼いだか目で見ながら出勤を耐えるアプリ — ターミナル・Macメニューバー・iPhone。

```
💸 +167,222ウォン [████████░░] 退勤まで 1:33:55
```

土日・祝日を除いた**実際の勤務日数**で日給を計算し、勤務時間中に秒単位で
カウントアップします。**残業は0円です** — 定時でカウンターが止まります 🫠
（そう、サービス残業は数字でもサービスです）

> ⚠️ 現在は韓国の祝日・ウォン(KRW)のみ対応です。
> 日本の祝日・円対応は[ロードマップ](기획.md)にあります。

## スクリーンショット

| キッチュ 🎀 | マトリックス 🖥️ |
|:---:|:---:|
| <img src="docs/screenshots/ios-kitsch.png" width="280"> | <img src="docs/screenshots/ios-matrix.png" width="280"> |

テーマ3種（キッチュ／フォーマル／マトリックス）＋ **シークレットモード 🕶️** —
金額の下3桁だけ表示（`+•••,222`）。隣の席に年収がバレません。
下3桁は動き続けるので「増えていく楽しさ」はそのまま。

## プラットフォーム

| | 形態 | インストール |
|---|---|---|
| 🐍 **CLI** | ターミナルティッカー、依存0・単一ファイル | `pipx install ./cli` → [使い方](cli/README.md) |
| 🖥️ **macOS** | メニューバーティッカー（毎秒更新、Dockなし） | [Releases](../../releases) から `.dmg` |
| 📱 **iOS** | カレンダーにハンコを押すアプリ＋ホームウィジェット | ソースからビルド（下記） |

## クイックスタート — CLI

```bash
brew install pipx && pipx ensurepath
git clone https://github.com/hebaek76916/doe-jang-work.git
pipx install ./doe-jang-work/cli

workstamp init --salary 5000   # 年収（万ウォン単位）
workstamp                      # リアルタイムティッカー
workstamp stamp                # 今日の出勤ハンコ、ポン 🔴
workstamp cal                  # 今月のハンコカレンダー
```

tmuxステータスバー・starshipプロンプトへの常駐方法は [cli/README.md](cli/README.md)。

## 一日の流れ

| 時間帯 | 表示 |
|---|---|
| 出勤1時間前 | 🏃 お金を稼ぎに行く途中 |
| 勤務中 | 💸 +167,222ウォン [████████░░] 退勤まで 1:33:55 |
| 退勤直後 | 🍻 稼ぎきった、お疲れさま！ |
| 定時2時間後もまだ画面の前 | 🫠 サービス残業中 |
| 土日・祝日 | 🧘 無給ヒーリング中 |

## ソースからビルド（iOS / macOS）

Xcodeプロジェクトは [XcodeGen](https://github.com/yonaskolb/XcodeGen) で生成します。

```bash
brew install xcodegen
xcodegen generate
open WorkStamp.xcodeproj
```

- **iOS**: スキーム `WorkStamp` → iPhoneシミュレータ（iOS 17+、ホームウィジェット含む）
- **macOS**: スキーム `WorkStampMac` → My Mac（macOS 14+）

## 構成

```
Sources/          iOSアプリ (SwiftUI)
Sources/Shared/   iOS・macOS共通 — 日給計算、勤務日カレンダー、テーマ、ハンコ保存
MacSources/       macOSメニューバーアプリ (NSStatusItem + SwiftUIポップオーバー)
WidgetSources/    iOSホームウィジェット (WidgetKit)
cli/              Python CLI（標準ライブラリのみ）
```

## ロードマップ

退勤プッシュ通知、連続出勤ストリーク、シェア用カード、
「このお金でラーメン何杯？」換算、日本語・中国語対応…
詳細（韓国語）: [기획.md](기획.md)

## ライセンス

[MIT](LICENSE)
