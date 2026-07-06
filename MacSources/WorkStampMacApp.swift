import SwiftUI
import AppKit

@main
struct WorkStampMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        // 창 없는 메뉴바 전용 앱. 실제 UI는 AppDelegate의 NSStatusItem이 담당.
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var timer: Timer?
    private let store = StampStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 메뉴바 상태 아이템 생성 (AppKit 표준 — MenuBarExtra보다 확실히 뜬다)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "wonsign.circle.fill", accessibilityDescription: "출근도장")
            button.imagePosition = .imageLeading
            button.action = #selector(togglePopover)
            button.target = self
        }
        updateTitle()

        // 팝오버 (키치 스티커 SwiftUI 뷰)
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 336, height: 420)
        popover.contentViewController = NSHostingController(rootView: MenuPopover(store: store))

        // 1초마다 메뉴바 텍스트 갱신
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTitle()
        }
    }

    private func updateTitle() {
        statusItem.button?.title = " " + labelText
    }

    private var labelText: String {
        guard store.annualSalary > 0 else { return L.tickerAppName }
        // 시크릿 모드: 끝 3자리만 — 초당 계속 바뀌어서 오르는 재미는 유지된다
        let earned = store.earnedSoFar().wonString(secret: store.isSecret)
        switch store.phase() {
        case .restDay: return L.tickerRest
        case .beforeWork: return L.tickerBefore
        case .commuting: return L.commuteTitle
        case .working: return "+\(earned)"
        case .justFinished: return L.tickerDone
        case .settled: return L.overtime
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // LSUIElement 앱은 비활성 상태라 스위치/피커가 클릭을 무시한다 — 먼저 활성화
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
