import SwiftUI

@main
struct WorkStampApp: App {
    @State private var store = StampStore()

    var body: some Scene {
        WindowGroup {
            if store.annualSalary > 0 {
                ContentView(store: store)
            } else {
                SalaryInputView(store: store)
            }
        }
    }
}
