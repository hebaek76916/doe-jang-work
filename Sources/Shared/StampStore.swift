import Foundation
import Observation
import WidgetKit

/// 하루의 근무 단계
enum WorkPhase: Equatable {
    case restDay        // 주말·공휴일
    case beforeWork     // 출근 1시간 전보다 이전
    case commuting      // 출근 전 1시간 쿠션 — 돈 벌러 가는 중
    case working        // 근무 중 — 실시간 카운팅
    case justFinished   // 퇴근 후 2시간 쿠션 — 다 벌었다 수고했다
    case settled        // 그 이후 — 확정
}

@Observable
final class StampStore {
    static let appGroupID = "group.com.toy.workstamp"

    /// 앱·위젯이 같이 읽는 저장소. App Group을 못 만들면 standard로 폴백.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    /// 연봉 (원 단위)
    var annualSalary: Int {
        didSet {
            Self.defaults.set(annualSalary, forKey: Self.salaryKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// 출근 시각 (자정 기준 분, 기본 09:00)
    var workStartMinutes: Int {
        didSet {
            Self.defaults.set(workStartMinutes, forKey: Self.workStartKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// 퇴근 시각 (자정 기준 분, 기본 18:00)
    var workEndMinutes: Int {
        didSet {
            Self.defaults.set(workEndMinutes, forKey: Self.workEndKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// 도장 찍은 날짜 (yyyy-MM-dd)
    private(set) var stampedDays: Set<String> {
        didSet {
            Self.defaults.set(Array(stampedDays), forKey: Self.stampsKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private static let salaryKey = "annualSalary"
    private static let stampsKey = "stampedDays"
    private static let workStartKey = "workStartMinutes"
    private static let workEndKey = "workEndMinutes"

    init() {
        Self.migrateFromStandardIfNeeded()
        let d = Self.defaults
        annualSalary = d.integer(forKey: Self.salaryKey)
        stampedDays = Set(d.stringArray(forKey: Self.stampsKey) ?? [])
        workStartMinutes = d.object(forKey: Self.workStartKey) as? Int ?? 9 * 60
        workEndMinutes = d.object(forKey: Self.workEndKey) as? Int ?? 18 * 60
    }

    /// App Group 도입 전 UserDefaults.standard에 있던 데이터를 한 번만 옮긴다.
    private static func migrateFromStandardIfNeeded() {
        let d = defaults
        guard d != UserDefaults.standard,
              d.integer(forKey: salaryKey) == 0,
              UserDefaults.standard.integer(forKey: salaryKey) > 0
        else { return }
        d.set(UserDefaults.standard.integer(forKey: salaryKey), forKey: salaryKey)
        d.set(UserDefaults.standard.stringArray(forKey: stampsKey) ?? [], forKey: stampsKey)
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

    // MARK: - 근무 시간 / 단계

    /// 해당 날짜의 출근·퇴근 시각
    func workInterval(on date: Date = .now) -> (start: Date, end: Date) {
        let cal = WorkdayCalendar.calendar
        let dayStart = cal.startOfDay(for: date)
        let start = dayStart.addingTimeInterval(TimeInterval(workStartMinutes * 60))
        let end = dayStart.addingTimeInterval(TimeInterval(workEndMinutes * 60))
        return (start, end)
    }

    func phase(at date: Date = .now) -> WorkPhase {
        guard WorkdayCalendar.isWorkday(date) else { return .restDay }
        let (start, end) = workInterval(on: date)
        if date < start.addingTimeInterval(-3600) { return .beforeWork }
        if date < start { return .commuting }
        if date < end { return .working }
        if date < end.addingTimeInterval(2 * 3600) { return .justFinished }
        return .settled
    }

    /// 지금까지 번 돈 (근무 중엔 경과 비율만큼, 퇴근 후엔 일급 전체)
    func earnedSoFar(at date: Date = .now) -> Int {
        let wage = dailyWage(year: WorkdayCalendar.calendar.component(.year, from: date))
        switch phase(at: date) {
        case .restDay, .beforeWork, .commuting:
            return 0
        case .working:
            let (start, end) = workInterval(on: date)
            let total = end.timeIntervalSince(start)
            guard total > 0 else { return wage }
            return Int(Double(wage) * date.timeIntervalSince(start) / total)
        case .justFinished, .settled:
            return wage
        }
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

// MARK: - 포맷

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

    /// 자정 기준 분 → "09:00"
    var hhmmString: String {
        String(format: "%02d:%02d", self / 60, self % 60)
    }
}
