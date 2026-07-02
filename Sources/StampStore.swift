import Foundation
import Observation

@Observable
final class StampStore {
    /// 연봉 (원 단위)
    var annualSalary: Int {
        didSet { UserDefaults.standard.set(annualSalary, forKey: Self.salaryKey) }
    }

    /// 도장 찍은 날짜 (yyyy-MM-dd)
    private(set) var stampedDays: Set<String> {
        didSet { UserDefaults.standard.set(Array(stampedDays), forKey: Self.stampsKey) }
    }

    private static let salaryKey = "annualSalary"
    private static let stampsKey = "stampedDays"

    init() {
        annualSalary = UserDefaults.standard.integer(forKey: Self.salaryKey)
        stampedDays = Set(UserDefaults.standard.stringArray(forKey: Self.stampsKey) ?? [])
    }

    // MARK: - 일급 계산

    func dailyWage(year: Int) -> Int {
        let days = WorkdayCalendar.workdayCount(year: year)
        guard days > 0 else { return 0 }
        return annualSalary / days
    }

    var todayWage: Int {
        dailyWage(year: WorkdayCalendar.calendar.component(.year, from: .now))
    }

    // MARK: - 도장

    func isStamped(_ date: Date) -> Bool {
        stampedDays.contains(WorkdayCalendar.dayKey(date))
    }

    /// 오늘 이전(포함)의 근무일만 찍고 뗄 수 있다.
    func canToggle(_ date: Date) -> Bool {
        WorkdayCalendar.isWorkday(date)
            && WorkdayCalendar.calendar.startOfDay(for: date) <= WorkdayCalendar.calendar.startOfDay(for: .now)
    }

    func toggleStamp(_ date: Date) {
        guard canToggle(date) else { return }
        let key = WorkdayCalendar.dayKey(date)
        if stampedDays.contains(key) {
            stampedDays.remove(key)
        } else {
            stampedDays.insert(key)
        }
    }

    // MARK: - 누적 금액

    /// 해당 월에 찍힌 도장 수
    func stampCount(year: Int, month: Int) -> Int {
        let prefix = String(format: "%04d-%02d-", year, month)
        return stampedDays.count { $0.hasPrefix(prefix) }
    }

    func stampCount(year: Int) -> Int {
        let prefix = String(format: "%04d-", year)
        return stampedDays.count { $0.hasPrefix(prefix) }
    }

    func earned(year: Int, month: Int) -> Int {
        stampCount(year: year, month: month) * dailyWage(year: year)
    }

    func earned(year: Int) -> Int {
        stampCount(year: year) * dailyWage(year: year)
    }
}

// MARK: - 금액 포맷

extension Int {
    /// 1234567 → "1,234,567원"
    var wonString: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return (f.string(from: NSNumber(value: self)) ?? "\(self)") + "원"
    }

    /// 50000000 → "5,000만원" (연봉 표시용)
    var manwonString: String {
        let man = self / 10_000
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return (f.string(from: NSNumber(value: man)) ?? "\(man)") + "만원"
    }
}
