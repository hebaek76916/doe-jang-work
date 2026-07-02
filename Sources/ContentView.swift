import SwiftUI

struct ContentView: View {
    @Bindable var store: StampStore
    @State private var displayedMonth: Date = WorkdayCalendar.calendar.startOfDay(for: .now)
    @State private var showSettings = false

    private var cal: Calendar { WorkdayCalendar.calendar }
    private var displayedYear: Int { cal.component(.year, from: displayedMonth) }
    private var displayedMonthNumber: Int { cal.component(.month, from: displayedMonth) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summaryCard
                    monthHeader
                    CalendarGridView(store: store, month: displayedMonth)
                    stampButton
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("출근도장")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsSheet(store: store)
            }
        }
    }

    // MARK: - 누적 요약

    private var summaryCard: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("이번 달 도장 \(store.stampCount(year: displayedYear, month: displayedMonthNumber))개")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(store.earned(year: displayedYear, month: displayedMonthNumber).wonString)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("하루 일급")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(store.dailyWage(year: displayedYear).wonString)
                        .font(.subheadline.bold())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(String(displayedYear))년 누적")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(store.earned(year: displayedYear).wonString)
                        .font(.subheadline.bold())
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
        .animation(.snappy, value: store.stampCount(year: displayedYear, month: displayedMonthNumber))
    }

    // MARK: - 월 이동

    private var monthHeader: some View {
        HStack {
            Button {
                moveMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text("\(String(displayedYear))년 \(displayedMonthNumber)월")
                .font(.headline)
            Spacer()
            Button {
                moveMonth(1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal, 8)
    }

    private func moveMonth(_ offset: Int) {
        if let next = cal.date(byAdding: .month, value: offset, to: displayedMonth) {
            withAnimation(.snappy) { displayedMonth = next }
        }
    }

    // MARK: - 오늘 도장 버튼

    private var stampButton: some View {
        let today = Date.now
        let stamped = store.isStamped(today)
        let isWorkday = WorkdayCalendar.isWorkday(today)

        return Button {
            withAnimation(.bouncy) { store.toggleStamp(today) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: stamped ? "checkmark.seal.fill" : "seal")
                Text(stamped
                    ? "오늘 \(store.todayWage.wonString) 벌었다!"
                    : isWorkday ? "오늘 출근 도장 찍기" : "오늘은 쉬는 날 🎉")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(stamped ? .green : .red)
        .disabled(!isWorkday)
        .padding(.bottom, 24)
    }
}

// MARK: - 달력 그리드

struct CalendarGridView: View {
    @Bindable var store: StampStore
    let month: Date

    private var cal: Calendar { WorkdayCalendar.calendar }
    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    /// 첫 주 빈칸(nil) + 해당 월의 날짜들
    private var dayCells: [Date?] {
        guard let interval = cal.dateInterval(of: .month, for: month) else { return [] }
        let firstWeekday = cal.component(.weekday, from: interval.start)
        let dayCount = cal.range(of: .day, in: .month, for: month)?.count ?? 0

        var cells: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for day in 0..<dayCount {
            cells.append(cal.date(byAdding: .day, value: day, to: interval.start))
        }
        return cells
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.bold())
                        .foregroundStyle(symbol == "일" ? .red : symbol == "토" ? .blue : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(Array(dayCells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCell(store: store, date: date)
                    } else {
                        Color.clear.frame(height: 48)
                    }
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
    }
}

struct DayCell: View {
    @Bindable var store: StampStore
    let date: Date

    private var cal: Calendar { WorkdayCalendar.calendar }
    private var day: Int { cal.component(.day, from: date) }
    private var isToday: Bool { cal.isDateInToday(date) }
    private var isWorkday: Bool { WorkdayCalendar.isWorkday(date) }
    private var stamped: Bool { store.isStamped(date) }

    var body: some View {
        Button {
            withAnimation(.bouncy) { store.toggleStamp(date) }
        } label: {
            ZStack {
                if isToday {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.red, lineWidth: 1.5)
                }
                VStack(spacing: 2) {
                    Text("\(day)")
                        .font(.caption2)
                        .foregroundStyle(isWorkday ? .primary : .tertiary)
                    if stamped {
                        StampMark()
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Color.clear.frame(width: 28, height: 28)
                    }
                }
            }
            .frame(height: 48)
        }
        .buttonStyle(.plain)
        .disabled(!store.canToggle(date))
    }
}

/// 빨간 인주 도장 모양
struct StampMark: View {
    var body: some View {
        Text("출근")
            .font(.system(size: 9, weight: .heavy))
            .foregroundStyle(.red)
            .frame(width: 26, height: 26)
            .overlay(Circle().strokeBorder(.red, lineWidth: 1.8))
            .rotationEffect(.degrees(-14))
            .opacity(0.85)
    }
}

// MARK: - 설정

struct SettingsSheet: View {
    @Bindable var store: StampStore
    @Environment(\.dismiss) private var dismiss
    @State private var salaryText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("연봉") {
                    HStack {
                        TextField("연봉", text: $salaryText)
                            .keyboardType(.numberPad)
                        Text("만원")
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    LabeledContent("올해 근무일", value: "\(WorkdayCalendar.workdayCount(year: WorkdayCalendar.calendar.component(.year, from: .now)))일")
                    LabeledContent("하루 일급", value: store.todayWage.wonString)
                } footer: {
                    Text("주말과 공휴일(대체공휴일 포함)을 제외한 근무일 기준입니다.")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        if let man = Int(salaryText), man > 0 {
                            store.annualSalary = man * 10_000
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
            .onAppear { salaryText = "\(store.annualSalary / 10_000)" }
        }
    }
}
