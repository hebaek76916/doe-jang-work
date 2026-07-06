import Foundation

/// 근무일 계산: 주말과 공휴일을 제외한다. 지역(L.region)에 따라 공휴일이 갈라진다.
/// - 한국: 대체공휴일 포함 2025–2027 (근사치)
/// - 일본: 振替休日·国民の休日 포함 2025–2027 (근사치)
/// - 중국: 法定节假日 연휴 + 调休 대체 "근무일"(주말인데 출근하는 날!) — 2025는 국무원 발표 기준,
///   2026–27은 미발표라 명절 위주 근사치 (调休 미반영)
enum WorkdayCalendar {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return cal
    }()

    // MARK: 한국
    private static let koreaHolidays: Set<String> = [
        "2025-01-01", "2025-01-27", "2025-01-28", "2025-01-29", "2025-01-30",
        "2025-03-03", "2025-05-05", "2025-05-06", "2025-06-03", "2025-06-06",
        "2025-08-15", "2025-10-03", "2025-10-06", "2025-10-07", "2025-10-08",
        "2025-10-09", "2025-12-25",
        "2026-01-01", "2026-02-16", "2026-02-17", "2026-02-18", "2026-03-02",
        "2026-05-05", "2026-05-25", "2026-08-17", "2026-09-24", "2026-09-25",
        "2026-09-28", "2026-10-05", "2026-10-09", "2026-12-25",
        "2027-01-01", "2027-02-08", "2027-02-09", "2027-03-01", "2027-05-05",
        "2027-05-13", "2027-08-16", "2027-09-14", "2027-09-15", "2027-09-16",
        "2027-10-04", "2027-10-11", "2027-12-27",
    ]

    // MARK: 일본 (振替休日·国民の休日 포함)
    private static let japanHolidays: Set<String> = [
        // 2025
        "2025-01-01", "2025-01-13", "2025-02-11", "2025-02-23", "2025-02-24",
        "2025-03-20", "2025-04-29", "2025-05-03", "2025-05-04", "2025-05-05",
        "2025-05-06", "2025-07-21", "2025-08-11", "2025-09-15", "2025-09-23",
        "2025-10-13", "2025-11-03", "2025-11-23", "2025-11-24",
        // 2026 (9/22는 国民の休日 — 실버위크)
        "2026-01-01", "2026-01-12", "2026-02-11", "2026-02-23", "2026-03-20",
        "2026-04-29", "2026-05-03", "2026-05-04", "2026-05-05", "2026-05-06",
        "2026-07-20", "2026-08-11", "2026-09-21", "2026-09-22", "2026-09-23",
        "2026-10-12", "2026-11-03", "2026-11-23",
        // 2027
        "2027-01-01", "2027-01-11", "2027-02-11", "2027-02-23", "2027-03-22",
        "2027-04-29", "2027-05-03", "2027-05-04", "2027-05-05", "2027-07-19",
        "2027-08-11", "2027-09-20", "2027-09-23", "2027-10-11", "2027-11-03",
        "2027-11-23",
    ]

    // MARK: 중국 (法定节假日 연휴)
    private static let chinaHolidays: Set<String> = [
        // 2025 — 국무원 발표 기준
        "2025-01-01",
        "2025-01-28", "2025-01-29", "2025-01-30", "2025-01-31", "2025-02-01",
        "2025-02-02", "2025-02-03", "2025-02-04",
        "2025-04-04", "2025-04-05", "2025-04-06",
        "2025-05-01", "2025-05-02", "2025-05-03", "2025-05-04", "2025-05-05",
        "2025-05-31", "2025-06-01", "2025-06-02",
        "2025-10-01", "2025-10-02", "2025-10-03", "2025-10-04", "2025-10-05",
        "2025-10-06", "2025-10-07", "2025-10-08",
        // 2026 — 미발표, 명절 근사치
        "2026-01-01", "2026-01-02",
        "2026-02-16", "2026-02-17", "2026-02-18", "2026-02-19", "2026-02-20",
        "2026-04-05", "2026-04-06",
        "2026-05-01", "2026-05-04", "2026-05-05",
        "2026-06-19",
        "2026-09-25",
        "2026-10-01", "2026-10-02", "2026-10-05", "2026-10-06", "2026-10-07",
        // 2027 — 미발표, 명절 근사치
        "2027-01-01",
        "2027-02-05", "2027-02-08", "2027-02-09", "2027-02-10", "2027-02-11",
        "2027-04-05",
        "2027-05-03", "2027-05-04", "2027-05-05",
        "2027-06-09",
        "2027-09-15",
        "2027-10-01", "2027-10-04", "2027-10-05", "2027-10-06", "2027-10-07",
    ]

    /// 중국 조휴(调休): 주말인데 출근하는 대체 근무일 — 2025 발표분만
    private static let chinaMakeupWorkdays: Set<String> = [
        "2025-01-26", "2025-02-08", "2025-04-27", "2025-09-28", "2025-10-11",
    ]

    private static func holidays(for region: Region) -> Set<String> {
        switch region {
        case .korea: koreaHolidays
        case .japan: japanHolidays
        case .china: chinaHolidays
        }
    }

    private static func makeupWorkdays(for region: Region) -> Set<String> {
        region == .china ? chinaMakeupWorkdays : []
    }

    static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dayKey(_ date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }

    static func isWeekend(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    static func isHoliday(_ date: Date) -> Bool {
        holidays(for: L.region).contains(dayKey(date))
    }

    static func isWorkday(_ date: Date) -> Bool {
        let key = dayKey(date)
        // 중국 조휴: 주말이어도 출근일
        if makeupWorkdays(for: L.region).contains(key) { return true }
        return !isWeekend(date) && !holidays(for: L.region).contains(key)
    }

    /// 해당 연도의 총 근무일 수
    static func workdayCount(year: Int) -> Int {
        guard let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let end = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        else { return 250 }

        var count = 0
        var date = start
        while date < end {
            if isWorkday(date) { count += 1 }
            guard let next = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = next
        }
        return count
    }
}
