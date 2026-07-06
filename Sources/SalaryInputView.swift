import SwiftUI

struct SalaryInputView: View {
    @Bindable var store: StampStore
    @State private var salaryText = ""
    @State private var workStart = WorkdayCalendar.calendar.date(from: DateComponents(hour: 9)) ?? .now
    @State private var workEnd = WorkdayCalendar.calendar.date(from: DateComponents(hour: 18)) ?? .now
    @FocusState private var focused: Bool

    private var salaryInput: Int { Int(salaryText) ?? 0 }

    /// 지역 관습에 따라 입력값 → 연봉 환산 (한국·일본: 만 단위 연봉, 중국: 월급×12)
    private var annualSalary: Int { store.region.annualSalary(fromInput: salaryInput) }

    private var previewWage: Int {
        let year = WorkdayCalendar.calendar.component(.year, from: .now)
        let days = WorkdayCalendar.workdayCount(year: year)
        guard days > 0 else { return 0 }
        return annualSalary / days
    }

    var body: some View {
        ZStack {
            Kitsch.cream.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("💰")
                    .font(.system(size: Kitsch.s(60)))
                    .padding(22)
                    .stickerCard(Kitsch.yellow, rotation: -4, cornerRadius: 28)

                // 국가 선택 — 언어·통화·공휴일·입력 관습이 갈라진다
                Picker(L.regionLabel, selection: $store.region) {
                    ForEach(Region.allCases, id: \.self) { region in
                        Text(region.label).tag(region)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                VStack(spacing: 10) {
                    Text(L.obTitle)
                        .font(.system(size: Kitsch.s(28), weight: .black, design: Kitsch.design))
                    Text(L.obSub)
                        .font(.system(size: Kitsch.s(14), weight: .bold))
                        .opacity(0.55)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 8) {
                    TextField(L.salaryPlaceholder, text: $salaryText)
                        .keyboardType(.numberPad)
                        .focused($focused)
                        .font(.system(size: Kitsch.s(40), weight: .black, design: Kitsch.design))
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 170)
                    Text(L.salaryUnit)
                        .font(.system(size: Kitsch.s(20), weight: .black))
                        .opacity(0.5)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .stickerCard(Kitsch.card, rotation: 1.2)

                HStack(spacing: 14) {
                    HStack(spacing: 2) {
                        Text(L.workStart)
                            .font(.system(size: Kitsch.s(14), weight: .black))
                        DatePicker("", selection: $workStart, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    HStack(spacing: 2) {
                        Text(L.workEnd)
                            .font(.system(size: Kitsch.s(14), weight: .black))
                        DatePicker("", selection: $workEnd, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .stickerCard(Kitsch.pastelYellow, rotation: -0.8, cornerRadius: 16)

                if salaryInput > 0 {
                    Text(L.obPreview(previewWage.wonString))
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
                    store.annualSalary = annualSalary
                } label: {
                    Text(L.startButton)
                        .font(.system(size: Kitsch.s(19), weight: .black, design: Kitsch.design))
                        .foregroundStyle(Kitsch.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(StickerButtonStyle(fill: Kitsch.pink))
                .disabled(salaryInput <= 0)
                .opacity(salaryInput > 0 ? 1 : 0.5)
                .padding(.bottom, 20)
            }
            .foregroundStyle(Kitsch.ink)
            .padding(.horizontal, 24)
            // 지역 바꾸면 언어·통화까지 전부 다시 그린다
            .id(store.region)
        }
        .fontDesign(Kitsch.design)
        .preferredColorScheme(Kitsch.theme == .matrix ? .dark : .light)
        .onAppear { focused = true }
    }
}
