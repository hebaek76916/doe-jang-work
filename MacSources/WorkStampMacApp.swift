import SwiftUI

@main
struct WorkStampMacApp: App {
    @State private var store = StampStore()

    var body: some Scene {
        MenuBarExtra {
            MenuPopover(store: store)
        } label: {
            // 메뉴바에 표시되는 티커. TimelineView로 근무 중엔 초 단위 갱신.
            MenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window)
    }
}

/// 메뉴바 티커 — 근무 단계에 따라 문구/금액이 실시간으로 바뀐다.
struct MenuBarLabel: View {
    let store: StampStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(labelText(at: context.date))
        }
    }

    private func labelText(at date: Date) -> String {
        guard store.annualSalary > 0 else { return "💼 출근도장" }
        let earned = store.earnedSoFar(at: date)
        switch store.phase(at: date) {
        case .restDay: return "🧘"
        case .beforeWork: return "🛌 출근 전"
        case .commuting: return "🏃 돈 벌러 가는 중"
        case .working: return "💸 +\(earned.wonString)"
        case .justFinished: return "🍻 다 벌었다"
        case .settled:
            // 퇴근 2시간 지났는데 아직 맥 앞 = 야근. 카운팅은 멈췄으니 무료봉사.
            return "🫠 무료봉사 중"
        }
    }
}
