import SwiftUI

struct ContentView: View {
    @Bindable var store: StampStore
    @State private var displayedMonth: Date = WorkdayCalendar.calendar.startOfDay(for: .now)
    @State private var showSettings = false

    private var cal: Calendar { WorkdayCalendar.calendar }
    private var displayedYear: Int { cal.component(.year, from: displayedMonth) }
    private var displayedMonthNumber: Int { cal.component(.month, from: displayedMonth) }

    var body: some View {
        ZStack {
            Kitsch.cream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 26) {
                    titleBar
                    summaryCard
                    calendarCard
                    stampButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .fontDesign(.rounded)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showSettings) {
            SettingsSheet(store: store)
        }
    }

    // MARK: - 타이틀

    private var titleBar: some View {
        HStack {
            Text("💸 출근도장")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.black)
            Spacer()
            Button {
                showSettings = true
            } label: {
                Text("⚙️")
                    .font(.system(size: 20))
                    .padding(10)
            }
            .buttonStyle(StickerButtonStyle(fill: .white, cornerRadius: 14))
        }
    }

    // MARK: - 누적 요약

    private var summaryCard: some View {
        VStack(spacing: 14) {
            Text("이번 달 모은 돈 ✨")
                .font(.system(size: 15, weight: .heavy))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .stickerCard(Kitsch.yellow, rotation: -2, cornerRadius: 999)

            Text(store.earned(year: displayedYear, month: displayedMonthNumber).wonString)
                .font(.system(size: 42, weight: .black, design: .rounded))
                .contentTransition(.numericText())
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("도장 \(store.stampCount(year: displayedYear, month: displayedMonthNumber))개 = 순도 100% 내 돈 🤑")
                .font(.system(size: 13, weight: .bold))
                .opacity(0.65)

            HStack(spacing: 10) {
                statChip(title: "하루 일급", value: store.dailyWage(year: displayedYear).wonString, fill: .white, rotation: 1.5)
                statChip(title: "올해 누적", value: store.earned(year: displayedYear).wonString, fill: Kitsch.pastelPurple, rotation: -1)
            }
        }
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .stickerCard(Kitsch.lime, rotation: -1.2)
        .animation(.snappy, value: store.stampCount(year: displayedYear, month: displayedMonthNumber))
    }

    private func statChip(title: String, value: String, fill: Color, rotation: Double) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .opacity(0.6)
            Text(value)
                .font(.system(size: 15, weight: .black))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .stickerCard(fill, rotation: rotation, cornerRadius: 14)
    }

    // MARK: - 달력

    private var calendarCard: some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    moveMonth(-1)
                } label: {
                    Text("👈")
                        .font(.system(size: 18))
                        .padding(8)
                }
                .buttonStyle(StickerButtonStyle(fill: Kitsch.yellow, cornerRadius: 12))

                Spacer()
                Text("\(String(displayedYear))년 \(displayedMonthNumber)월")
                    .font(.system(size: 20, weight: .black))
                Spacer()

                Button {
                    moveMonth(1)
                } label: {
                    Text("👉")
                        .font(.system(size: 18))
                        .padding(8)
                }
                .buttonStyle(StickerButtonStyle(fill: Kitsch.yellow, cornerRadius: 12))
            }

            CalendarGridView(store: store, month: displayedMonth)
        }
        .foregroundStyle(.black)
        .padding(16)
        .stickerCard(.white, rotation: 0.8)
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
            Text(stamped
                ? "오늘 +\(store.todayWage.wonString) 순삭 🤑"
                : isWorkday ? "출근 도장 쾅 💥" : "쉬는 날 = 무급 힐링 🧘")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
        }
        .buttonStyle(StickerButtonStyle(fill: stamped ? Kitsch.pastelBlue : Kitsch.pink))
        .disabled(!isWorkday)
        .opacity(isWorkday ? 1 : 0.5)
        .padding(.bottom, 30)
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
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(symbol == "일" ? Kitsch.pink : symbol == "토" ? Kitsch.blue : .black.opacity(0.45))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(Array(dayCells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCell(store: store, date: date)
                    } else {
                        Color.clear.frame(height: 50)
                    }
                }
            }
        }
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
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Kitsch.yellow.opacity(0.55))
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.black, lineWidth: 2)
                }
                VStack(spacing: 2) {
                    Text("\(day)")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(isWorkday ? .black : .black.opacity(0.25))
                    if stamped {
                        StampMark()
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Color.clear.frame(width: 30, height: 30)
                    }
                }
            }
            .frame(height: 50)
        }
        .buttonStyle(.plain)
        .disabled(!store.canToggle(date))
    }
}

/// 삐뚤게 찍힌 인주 도장 스티커
struct StampMark: View {
    var body: some View {
        Text("출근")
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background {
                ZStack {
                    Circle().fill(.black).offset(x: 2, y: 2.5)
                    Circle().fill(Kitsch.pink)
                    Circle().strokeBorder(.black, lineWidth: 2)
                }
            }
            .rotationEffect(.degrees(-14))
    }
}

// MARK: - 설정

struct SettingsSheet: View {
    @Bindable var store: StampStore
    @Environment(\.dismiss) private var dismiss
    @State private var salaryText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Kitsch.cream.ignoresSafeArea()

                VStack(spacing: 20) {
                    HStack {
                        Text("연봉")
                            .font(.system(size: 16, weight: .black))
                        TextField("연봉", text: $salaryText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 20, weight: .black, design: .rounded))
                        Text("만원")
                            .font(.system(size: 15, weight: .bold))
                            .opacity(0.5)
                    }
                    .padding(18)
                    .stickerCard(.white, rotation: -0.8)

                    VStack(spacing: 10) {
                        HStack {
                            Text("올해 근무일")
                                .font(.system(size: 14, weight: .bold))
                                .opacity(0.6)
                            Spacer()
                            Text("\(WorkdayCalendar.workdayCount(year: WorkdayCalendar.calendar.component(.year, from: .now)))일")
                                .font(.system(size: 15, weight: .black))
                        }
                        HStack {
                            Text("하루 일급")
                                .font(.system(size: 14, weight: .bold))
                                .opacity(0.6)
                            Spacer()
                            Text(store.todayWage.wonString)
                                .font(.system(size: 15, weight: .black))
                        }
                        Text("주말·공휴일(대체공휴일 포함) 빼고 계산해요")
                            .font(.system(size: 11, weight: .bold))
                            .opacity(0.4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(18)
                    .stickerCard(Kitsch.pastelYellow, rotation: 0.8)

                    Spacer()

                    Button {
                        if let man = Int(salaryText), man > 0 {
                            store.annualSalary = man * 10_000
                        }
                        dismiss()
                    } label: {
                        Text("저장 💾")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(StickerButtonStyle(fill: Kitsch.lime))
                }
                .foregroundStyle(.black)
                .padding(20)
            }
            .fontDesign(.rounded)
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                        .tint(.black)
                }
            }
            .onAppear { salaryText = "\(store.annualSalary / 10_000)" }
        }
        .preferredColorScheme(.light)
    }
}
