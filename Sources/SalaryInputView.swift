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
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("💼")
                    .font(.system(size: 64))
                Text("연봉을 입력해 주세요")
                    .font(.title2.bold())
                Text("주말·공휴일을 뺀 근무일 기준으로\n하루에 얼마 버는지 알려드려요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 8) {
                TextField("5,000", text: $salaryText)
                    .keyboardType(.numberPad)
                    .focused($focused)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 180)
                Text("만원")
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))

            if salaryManwon > 0 {
                VStack(spacing: 4) {
                    Text("하루 출근하면")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(previewWage.wonString)
                        .font(.title.bold())
                        .foregroundStyle(.red)
                        .contentTransition(.numericText())
                }
                .animation(.snappy, value: previewWage)
            }

            Spacer()

            Button {
                store.annualSalary = salaryManwon * 10_000
            } label: {
                Text("시작하기")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(salaryManwon <= 0)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onAppear { focused = true }
    }
}
