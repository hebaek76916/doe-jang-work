import Foundation

/// 서비스 지역 — 언어·통화·공휴일·연봉 입력 관습을 한꺼번에 결정한다.
enum Region: String, CaseIterable {
    case korea
    case japan
    case china

    var flag: String {
        switch self { case .korea: "🇰🇷"; case .japan: "🇯🇵"; case .china: "🇨🇳" }
    }

    var label: String {
        switch self { case .korea: "🇰🇷 한국"; case .japan: "🇯🇵 日本"; case .china: "🇨🇳 中国" }
    }

    /// 통화 접미사
    var currency: String {
        switch self { case .korea: "원"; case .japan: "円"; case .china: "元" }
    }

    /// 연봉 입력 단위: 한국·일본은 만 단위 연봉, 중국은 월급(月薪) 사고방식
    var salaryIsMonthly: Bool { self == .china }

    /// 입력값 → 연봉(현지 통화 원 단위)
    func annualSalary(fromInput n: Int) -> Int {
        salaryIsMonthly ? n * 12 : n * 10_000
    }

    /// 연봉 → 입력 필드 표시값
    func inputValue(fromAnnual annual: Int) -> Int {
        salaryIsMonthly ? annual / 12 : annual / 10_000
    }
}

/// 지역별 카피 테이블 — 번역이 아니라 재창작 (기획 원칙).
/// StampStore.region이 `L.region`을 동기화한다.
enum L {
    static var region: Region = .korea

    // MARK: 금액
    static func money(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return (f.string(from: NSNumber(value: n)) ?? "\(n)") + region.currency
    }

    /// 시크릿: 끝 3자리만 (끝자리는 계속 바뀌어서 오르는 재미 유지)
    static func maskedMoney(_ n: Int) -> String {
        guard abs(n) >= 1000 else { return "•••" + region.currency }
        return "•••,\(String(format: "%03d", abs(n) % 1000))" + region.currency
    }

    static func money(_ n: Int, secret: Bool) -> String {
        secret ? maskedMoney(n) : money(n)
    }

    // MARK: 공통 카피 (ko / ja / zh)
    private static func t(_ ko: String, _ ja: String, _ zh: String) -> String {
        switch region { case .korea: ko; case .japan: ja; case .china: zh }
    }

    static var appTitle: String { t("💸 출근도장", "💸 出勤ハンコ", "💸 上班打卡") }

    // 라이브 카드 / 근무 단계
    static var restTitle: String { t("오늘은 무급 힐링", "今日は無給ヒーリング", "今天0元疗愈") }
    static var restSub: String { t("쉬는 것도 일이다", "休むのも仕事", "躺平也是修行") }
    static var restZero: String { t("0원도 힐링이면 OK", "0円でもヒーリングならOK", "0元也是一种疗愈") }
    static var beforeTitle: String { t("아직 출근 전", "まだ出勤前", "还没上班") }
    static func beforeSub(_ time: String) -> String {
        t("\(time)부터 돈이 오릅니다", "\(time)からお金が増えます", "\(time)开始涨钱")
    }
    static var commuteTitle: String { t("돈 벌러 가는 중", "お金を稼ぎに行く途中", "搬砖路上") }
    static func commuteSub(_ time: String) -> String {
        t("\(time)부터 카운트 시작!", "\(time)からカウント開始！", "\(time)开始计数！")
    }
    static var workingTitle: String { t("지금 벌고 있는 중", "いま稼いでる最中", "正在赚钱中") }
    static var untilOff: String { t("퇴근까지", "退勤まで", "距下班") }
    static var doneTitle: String { t("오늘 돈 다 벌었다!", "今日は稼ぎきった！", "今天赚满收工！") }
    static func doneSub(_ m: String) -> String {
        t("+\(m) — 수고했다 진짜", "+\(m) お疲れさま！", "+\(m) 辛苦了！")
    }
    static var settledTitleStamped: String { t("오늘 진짜 벌었다", "今日ちゃんと稼いだ", "今天真的赚到了") }
    static var settledTitleNoStamp: String { t("돈은 벌었는데 도장을 안 찍음 👀", "稼いだのにハンコ押してない 👀", "钱赚了卡没打 👀") }
    static func settledSub(_ m: String) -> String {
        t("+\(m) 확정", "+\(m) 確定", "+\(m) 落袋为安")
    }
    static var overtime: String { t("무료봉사 중", "サービス残業中", "白干中") }
    static var overtimePhase: String { t("정시 이후 = 무료봉사 🫠", "定時後 = サービス残業 🫠", "下班后 = 白干 🫠") }

    // 요약 카드
    static var monthEarnedBadge: String { t("이번 달 모은 돈 ✨", "今月稼いだお金 ✨", "本月已入账 ✨") }
    static func stampCountLine(_ n: Int) -> String {
        t("도장 \(n)개 = 순도 100% 내 돈 🤑", "ハンコ\(n)個 = 純度100%の自分のお金 🤑", "打卡\(n)次 = 100%属于我的钱 🤑")
    }
    static var dailyWage: String { t("하루 일급", "日給", "日薪") }
    static var yearTotal: String { t("올해 누적", "今年の累計", "今年累计") }

    // 달력
    static func monthTitle(_ y: Int, _ m: Int) -> String {
        t("\(String(y))년 \(m)월", "\(String(y))年\(m)月", "\(String(y))年\(m)月")
    }
    static var weekdaySymbols: [String] {
        switch region {
        case .korea: ["일", "월", "화", "수", "목", "금", "토"]
        case .japan: ["日", "月", "火", "水", "木", "金", "土"]
        case .china: ["日", "一", "二", "三", "四", "五", "六"]
        }
    }
    static var stampMark: String { t("출근", "出勤", "打卡") }

    // 도장 버튼
    static func stampButtonStamped(_ m: String) -> String {
        t("오늘 +\(m) 순삭 🤑", "今日 +\(m) ゲット 🤑", "今天 +\(m) 到手 🤑")
    }
    static var stampButtonGo: String { t("출근 도장 쾅 💥", "出勤ハンコ、ポン 💥", "上班打卡 💥") }
    static var stampButtonRest: String { t("쉬는 날 = 무급 힐링 🧘", "休みの日 = 無給ヒーリング 🧘", "休息日 = 0元疗愈 🧘") }
    static var stampedToday: String { t("오늘 도장 찍음 ✅", "今日はハンコ済み ✅", "今日已打卡 ✅") }

    // 온보딩
    static var obTitle: String {
        t("연봉 얼마 받음?", "年収いくら？", "月薪多少？")
    }
    static var obSub: String {
        t("🤫 아무한테도 말 안 함\n주말·공휴일 빼고 하루에 얼마 버는지 알려줌",
          "🤫 誰にも言いません\n土日祝を除いて1日いくら稼ぐか教えます",
          "🤫 谁也不告诉\n扣除周末节假日，算你每天赚多少")
    }
    static var salaryUnit: String { t("만원", "万円", "元/月") }
    static var salaryPlaceholder: String { t("1,000", "500", "10000") }
    static func obPreview(_ m: String) -> String {
        t("하루 출근 = \(m) 🤑", "出勤1日 = \(m) 🤑", "上一天班 = \(m) 🤑")
    }
    static var startButton: String { t("시작하기 🚀", "はじめる 🚀", "开始 🚀") }

    // 설정
    static var settingsTitle: String { t("설정", "設定", "设置") }
    static var salaryLabel: String { t("연봉", "年収", "月薪") }
    static var workStart: String { t("출근", "出勤", "上班") }
    static var workEnd: String { t("퇴근", "退勤", "下班") }
    static var themeLabel: String { t("테마", "テーマ", "主题") }
    static var regionLabel: String { t("국가", "国・地域", "国家") }
    static var secretTitle: String { t("시크릿 모드 🕶️", "シークレットモード 🕶️", "隐身模式 🕶️") }
    static var secretDesc: String {
        t("금액 끝 3자리만 표시 — 큰 금액은 꾹 눌러서 확인",
          "下3桁だけ表示 — 長押しで金額を確認",
          "只显示末3位 — 长按查看金额")
    }
    static var secretDescShort: String {
        t("시크릿 모드 🕶️ — 금액 끝 3자리만 표시", "シークレット 🕶️ — 下3桁だけ表示", "隐身模式 🕶️ — 只显示末3位")
    }
    static var workdaysThisYear: String { t("올해 근무일", "今年の勤務日", "今年工作日") }
    static func days(_ n: Int) -> String { t("\(n)일", "\(n)日", "\(n)天") }
    static var holidayNote: String {
        t("주말·공휴일(대체공휴일 포함) 빼고 계산해요",
          "土日祝（振替休日込み）を除いて計算します",
          "扣除周末和法定节假日（含调休）计算")
    }
    static var save: String { t("저장 💾", "保存 💾", "保存 💾") }
    static var cancel: String { t("취소", "キャンセル", "取消") }
    static var close: String { t("닫기", "閉じる", "关闭") }

    // 테마 라벨
    static func themeName(_ theme: AppTheme) -> String {
        switch theme {
        case .kitsch: t("키치 🎀", "キッチュ 🎀", "可爱 🎀")
        case .formal: t("포멀 👔", "フォーマル 👔", "正式 👔")
        case .matrix: t("매트릭스 🖥️", "マトリックス 🖥️", "黑客 🖥️")
        }
    }

    // macOS 메뉴바·팝오버
    static var quit: String { t("종료", "終了", "退出") }
    static var quitTitle: String { t("출근도장을 종료할까요?", "出勤ハンコを終了しますか？", "要退出上班打卡吗？") }
    static var quitMessage: String {
        t("종료하면 메뉴바 티커가 사라져요. 돈은 계속 벌리는데 안 보임 🥲",
          "終了するとティッカーが消えます。お金は増え続けるのに見えない 🥲",
          "退出后计数器会消失。钱还在涨但你看不见了 🥲")
    }
    static var calFold: String { t("달력 접기", "カレンダーを閉じる", "收起日历") }
    static var calUnfold: String { t("달력 펼치기 📅", "カレンダーを開く 📅", "展开日历 📅") }
    static var todayWageChip: String { t("오늘 일급", "今日の日給", "今日日薪") }
    static var monthChip: String { t("이번 달", "今月", "本月") }
    static var tickerAppName: String { t("출근도장", "出勤ハンコ", "上班打卡") }
    static var tickerRest: String { t("무급 힐링", "無給ヒーリング", "0元疗愈") }
    static var tickerBefore: String { t("출근 전", "出勤前", "还没上班") }
    static var tickerDone: String { t("다 벌었다", "稼ぎきった", "赚满收工") }
    static func expectedToday(_ m: String) -> String {
        t("오늘 \(m) 예정", "今日 \(m) 予定", "今天预计 \(m)")
    }

    // 위젯
    static var setupFirst: String { t("앱에서 연봉부터!", "アプリで年収設定を！", "先去App里设置薪资！") }
    static var widgetName: String { t("실시간 벌이", "リアルタイム収入", "实时收入") }
    static var widgetDesc: String {
        t("일하는 동안 돈이 쌓이는 걸 지켜보세요 💸", "働いている間にお金が増えるのを眺めよう 💸", "看着钱在上班时间一点点涨 💸")
    }
}
