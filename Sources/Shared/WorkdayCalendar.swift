import Foundation

/// 근무일 계산: 주말과 한국 공휴일(대체공휴일 포함)을 제외한다.
/// 공휴일 데이터는 2025–2027년만 내장하며, 그 외 연도는 주말만 제외한다.
enum WorkdayCalendar {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return cal
    }()

    /// yyyy-MM-dd 형식의 공휴일 목록 (음력 명절·대체공휴일 반영, 근사치)
    static let holidays: Set<String> = [
        // 2025
        "2025-01-01", "2025-01-27", "2025-01-28", "2025-01-29", "2025-01-30",
        "2025-03-03", "2025-05-05", "2025-05-06", "2025-06-03", "2025-06-06",
        "2025-08-15", "2025-10-03", "2025-10-06", "2025-10-07", "2025-10-08",
        "2025-10-09", "2025-12-25",
        // 2026
        "2026-01-01", "2026-02-16", "2026-02-17", "2026-02-18", "2026-03-02",
        "2026-05-05", "2026-05-25", "2026-08-17", "2026-09-24", "2026-09-25",
        "2026-09-28", "2026-10-05", "2026-10-09", "2026-12-25",
        // 2027
        "2027-01-01", "2027-02-08", "2027-02-09", "2027-03-01", "2027-05-05",
        "2027-05-13", "2027-08-16", "2027-09-14", "2027-09-15", "2027-09-16",
        "2027-10-04", "2027-10-11", "2027-12-27",
    ]

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
        holidays.contains(dayKey(date))
    }

    static func isWorkday(_ date: Date) -> Bool {
        !isWeekend(date) && !isHoliday(date)
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
