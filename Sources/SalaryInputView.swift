import SwiftUI

struct SalaryInputView: View {
    @Bindable var store: StampStore
    @State private var salaryText = ""
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
                    .font(.system(size: 60))
                    .padding(22)
                    .stickerCard(Kitsch.yellow, rotation: -4, cornerRadius: 28)

                VStack(spacing: 10) {
                    Text("연봉 얼마 받음?")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                    Text("🤫 아무한테도 말 안 함\n주말·공휴일 빼고 하루에 얼마 버는지 알려줌")
                        .font(.system(size: 14, weight: .bold))
                        .opacity(0.55)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 8) {
                    TextField("5,000", text: $salaryText)
                        .keyboardType(.numberPad)
                        .focused($focused)
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 170)
                    Text("만원")
                        .font(.system(size: 20, weight: .black))
                        .opacity(0.5)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .stickerCard(.white, rotation: 1.2)

                if salaryManwon > 0 {
                    Text("하루 출근 = \(previewWage.wonString) 🤑")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .stickerCard(Kitsch.lime, rotation: -1.5, cornerRadius: 999)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: previewWage)
                }

                Spacer()

                Button {
                    store.annualSalary = salaryManwon * 10_000
                } label: {
                    Text("시작하기 🚀")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(StickerButtonStyle(fill: Kitsch.pink))
                .disabled(salaryManwon <= 0)
                .opacity(salaryManwon > 0 ? 1 : 0.5)
                .padding(.bottom, 20)
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 24)
        }
        .fontDesign(.rounded)
        .preferredColorScheme(.light)
        .onAppear { focused = true }
    }
}
