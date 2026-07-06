import SwiftUI

struct SalaryInputView: View {
    @Bindable var store: StampStore
    @State private var salaryText = ""
    @State private var workStart = WorkdayCalendar.calendar.date(from: DateComponents(hour: 9)) ?? .now
    @State private var workEnd = WorkdayCalendar.calendar.date(from: DateComponents(hour: 18)) ?? .now
    @FocusState private var focused: Bool

    private var salaryManwon: Int { Int(salaryText) ?? 0 }

    private var previewWage: Int {
        let year = WorkdayCalendar.calendar.component(.year, from: .now)
        let days = WorkdayCalendar.workdayCount(year: year)
        guard days > 0 else { return 0 }
        return salaryManwon * 10_000 / days
    }

    var body: some View {
        ZStack {
            Kitsch.cream.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("💰")
                    .font(.system(size: Kitsch.s(60)))
                    .padding(22)
                    .stickerCard(Kitsch.yellow, rotation: -4, cornerRadius: 28)

                VStack(spacing: 10) {
                    Text("연봉 얼마 받음?")
                        .font(.system(size: Kitsch.s(28), weight: .black, design: Kitsch.design))
                    Text("🤫 아무한테도 말 안 함\n주말·공휴일 빼고 하루에 얼마 버는지 알려줌")
                        .font(.system(size: Kitsch.s(14), weight: .bold))
                        .opacity(0.55)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 8) {
                    TextField("1,000", text: $salaryText)
                        .keyboardType(.numberPad)
                        .focused($focused)
                        .font(.system(size: Kitsch.s(40), weight: .black, design: Kitsch.design))
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 170)
                    Text("만원")
                        .font(.system(size: Kitsch.s(20), weight: .black))
                        .opacity(0.5)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .stickerCard(Kitsch.card, rotation: 1.2)

                HStack(spacing: 14) {
                    HStack(spacing: 2) {
                        Text("출근")
                            .font(.system(size: Kitsch.s(14), weight: .black))
                        DatePicker("", selection: $workStart, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    HStack(spacing: 2) {
                        Text("퇴근")
                            .font(.system(size: Kitsch.s(14), weight: .black))
                        DatePicker("", selection: $workEnd, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .stickerCard(Kitsch.pastelYellow, rotation: -0.8, cornerRadius: 16)

                if salaryManwon > 0 {
                    Text("하루 출근 = \(previewWage.wonString) 🤑")
                        .font(.system(size: Kitsch.s(18), weight: .black, design: Kitsch.design))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .stickerCard(Kitsch.lime, rotation: -1.5, cornerRadius: 999)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: previewWage)
                }

                Spacer()

                Button {
                    let cal = WorkdayCalendar.calendar
                    store.workStartMinutes = cal.component(.hour, from: workStart) * 60 + cal.component(.minute, from: workStart)
                    store.workEndMinutes = cal.component(.hour, from: workEnd) * 60 + cal.component(.minute, from: workEnd)
                    store.annualSalary = salaryManwon * 10_000
                } label: {
                    Text("시작하기 🚀")
                        .font(.system(size: Kitsch.s(19), weight: .black, design: Kitsch.design))
                        .foregroundStyle(Kitsch.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(StickerButtonStyle(fill: Kitsch.pink))
                .disabled(salaryManwon <= 0)
                .opacity(salaryManwon > 0 ? 1 : 0.5)
                .padding(.bottom, 20)
            }
            .foregroundStyle(Kitsch.ink)
            .padding(.horizontal, 24)
        }
        .fontDesign(Kitsch.design)
        .preferredColorScheme(Kitsch.theme == .matrix ? .dark : .light)
        .onAppear { focused = true }
    }
}
