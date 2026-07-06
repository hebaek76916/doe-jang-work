import SwiftUI

struct ContentView: View {
    @Bindable var store: StampStore
    @State private var displayedMonth: Date = WorkdayCalendar.calendar.startOfDay(for: .now)
    @State private var showSettings = false
    @State private var peeking = false

    private var cal: Calendar { WorkdayCalendar.calendar }
    private var displayedYear: Int { cal.component(.year, from: displayedMonth) }
    private var displayedMonthNumber: Int { cal.component(.month, from: displayedMonth) }
    /// 시크릿 모드 + 꾹 누르는 동안(peek)은 잠깐 해제
    private var secret: Bool { store.isSecret && !peeking }

    var body: some View {
        ZStack {
            Kitsch.cream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 26) {
                    titleBar
                    liveCard
                    summaryCard
                    calendarCard
                    stampButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            // 테마 토글 시 StickerCard 등 정적 팔레트를 쓰는 뷰까지 전부 다시 그린다
            .id("\(store.theme.rawValue)-\(store.region.rawValue)")
        }
        .fontDesign(Kitsch.design)
        .preferredColorScheme(Kitsch.theme == .matrix ? .dark : .light)
        .sheet(isPresented: $showSettings) {
            SettingsSheet(store: store)
        }
    }

    // MARK: - 타이틀

    private var titleBar: some View {
        HStack {
            Text(L.appTitle)
                .font(.system(size: Kitsch.s(28), weight: .black, design: Kitsch.design))
                .foregroundStyle(Kitsch.ink)
            Spacer()
            Button {
                showSettings = true
            } label: {
                Text("⚙️")
                    .font(.system(size: Kitsch.s(20)))
                    .padding(10)
            }
            .buttonStyle(StickerButtonStyle(fill: Kitsch.card, cornerRadius: 14))
        }
    }

    // MARK: - 실시간 벌이 카드

    /// 근무 단계에 따라 초 단위로 갱신되는 오늘의 상태 카드
    private var liveCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let phase = store.phase(at: context.date)
            let earned = store.earnedSoFar(at: context.date)

            Group {
                switch phase {
                case .restDay:
                    liveCardBody(emoji: "🧘", title: L.restTitle, subtitle: L.restSub, fill: Kitsch.pastelBlue, rotation: 0.8)
                case .beforeWork:
                    liveCardBody(emoji: "🛌", title: L.beforeTitle, subtitle: L.beforeSub(store.workStartMinutes.hhmmString), fill: Kitsch.card, rotation: -0.6)
                case .commuting:
                    liveCardBody(emoji: "🏃", title: L.commuteTitle, subtitle: L.commuteSub(store.workStartMinutes.hhmmString), fill: Kitsch.pastelYellow, rotation: -1)
                case .working:
                    workingCard(earned: earned, at: context.date)
                case .justFinished:
                    liveCardBody(emoji: "🍻", title: L.doneTitle, subtitle: L.doneSub(earned.wonString(secret: secret)), fill: Kitsch.lime, rotation: -1.2)
                case .settled:
                    liveCardBody(emoji: "🤑", title: store.isStamped(context.date) ? L.settledTitleStamped : L.settledTitleNoStamp, subtitle: L.settledSub(earned.wonString(secret: secret)), fill: Kitsch.pastelPurple, rotation: 0.6)
                }
            }
        }
    }

    private func liveCardBody(emoji: String, title: String, subtitle: String, fill: Color, rotation: Double) -> some View {
        HStack(spacing: 12) {
            Text(emoji).font(.system(size: Kitsch.s(30)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: Kitsch.s(16), weight: .black))
                Text(subtitle)
                    .font(.system(size: Kitsch.s(12), weight: .bold))
                    .opacity(0.55)
            }
            Spacer()
        }
        .foregroundStyle(Kitsch.ink)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .stickerCard(fill, rotation: rotation, cornerRadius: 18)
    }

    private func workingCard(earned: Int, at date: Date) -> some View {
        let (start, end) = store.workInterval(on: date)
        let progress = min(max(date.timeIntervalSince(start) / end.timeIntervalSince(start), 0), 1)
        let remaining = Int(end.timeIntervalSince(date))

        return VStack(spacing: 10) {
            HStack {
                Text("💸 \(L.workingTitle)")
                    .font(.system(size: Kitsch.s(14), weight: .black))
                Spacer()
                Text("\(L.untilOff) \(remaining / 3600):\(String(format: "%02d", remaining % 3600 / 60)):\(String(format: "%02d", remaining % 60))")
                    .font(.system(size: Kitsch.s(12), weight: .black))
                    .monospacedDigit()
                    .opacity(0.55)
            }
            Text("+\(earned.wonString(secret: secret))")
                .font(.system(size: Kitsch.s(34), weight: .black, design: Kitsch.design))
                .foregroundStyle(Kitsch.pink)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.4), value: earned)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Kitsch.card)
                    Capsule().fill(Kitsch.pink)
                        .frame(width: max(geo.size.width * progress, 12))
                    Capsule().strokeBorder(.black, lineWidth: 2)
                }
            }
            .frame(height: 14)
        }
        .foregroundStyle(Kitsch.ink)
        .padding(16)
        .stickerCard(Kitsch.pastelYellow, rotation: -1, cornerRadius: 18)
    }

    // MARK: - 누적 요약

    private var summaryCard: some View {
        VStack(spacing: 14) {
            Text(L.monthEarnedBadge)
                .font(.system(size: Kitsch.s(15), weight: .heavy))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .stickerCard(Kitsch.yellow, rotation: -2, cornerRadius: 999)

            Text(store.earned(year: displayedYear, month: displayedMonthNumber).wonString(secret: secret))
                .font(.system(size: Kitsch.s(42), weight: .black, design: Kitsch.design))
                .contentTransition(.numericText())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                // 시크릿 모드에서 꾹 누르는 동안만 진짜 금액 표시
                .onLongPressGesture(minimumDuration: .infinity) {} onPressingChanged: { pressing in
                    withAnimation(.snappy) { peeking = pressing }
                }

            Text(L.stampCountLine(store.stampCount(year: displayedYear, month: displayedMonthNumber)))
                .font(.system(size: Kitsch.s(13), weight: .bold))
                .opacity(0.65)

            HStack(spacing: 10) {
                statChip(title: L.dailyWage, value: store.dailyWage(year: displayedYear).wonString(secret: secret), fill: Kitsch.card, rotation: 1.5)
                statChip(title: L.yearTotal, value: store.earned(year: displayedYear).wonString(secret: secret), fill: Kitsch.pastelPurple, rotation: -1)
            }
        }
        .foregroundStyle(Kitsch.ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .stickerCard(Kitsch.lime, rotation: -1.2)
        .animation(.snappy, value: store.stampCount(year: displayedYear, month: displayedMonthNumber))
    }

    private func statChip(title: String, value: String, fill: Color, rotation: Double) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: Kitsch.s(11), weight: .bold))
                .opacity(0.6)
            Text(value)
                .font(.system(size: Kitsch.s(15), weight: .black))
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
                        .font(.system(size: Kitsch.s(18)))
                        .padding(8)
                }
                .buttonStyle(StickerButtonStyle(fill: Kitsch.yellow, cornerRadius: 12))

                Spacer()
                Text(L.monthTitle(displayedYear, displayedMonthNumber))
                    .font(.system(size: Kitsch.s(20), weight: .black))
                Spacer()

                Button {
                    moveMonth(1)
                } label: {
                    Text("👉")
                        .font(.system(size: Kitsch.s(18)))
                        .padding(8)
                }
                .buttonStyle(StickerButtonStyle(fill: Kitsch.yellow, cornerRadius: 12))
            }

            CalendarGridView(store: store, month: displayedMonth)
        }
        .foregroundStyle(Kitsch.ink)
        .padding(16)
        .stickerCard(Kitsch.card, rotation: 0.8)
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
                ? L.stampButtonStamped(store.todayWage.wonString(secret: secret))
                : isWorkday ? L.stampButtonGo : L.stampButtonRest)
                .font(.system(size: Kitsch.s(19), weight: .black, design: Kitsch.design))
                .foregroundStyle(Kitsch.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
        }
        .buttonStyle(StickerButtonStyle(fill: stamped ? Kitsch.pastelBlue : Kitsch.pink))
        .disabled(!isWorkday)
        .opacity(isWorkday ? 1 : 0.5)
        .padding(.bottom, 30)
    }
}

// 달력 컴포넌트(CalendarGridView·DayCell·StampMark)는 Sources/Shared/CalendarView.swift로 이동 — macOS와 공유

// MARK: - 설정

struct SettingsSheet: View {
    @Bindable var store: StampStore
    @Environment(\.dismiss) private var dismiss
    @State private var salaryText = ""
    @State private var workStart = Date.now
    @State private var workEnd = Date.now

    var body: some View {
        NavigationStack {
            ZStack {
                Kitsch.cream.ignoresSafeArea()

                VStack(spacing: 20) {
                    HStack {
                        Text(L.salaryLabel)
                            .font(.system(size: Kitsch.s(16), weight: .black))
                        TextField(L.salaryLabel, text: $salaryText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: Kitsch.s(20), weight: .black, design: Kitsch.design))
                        Text(L.salaryUnit)
                            .font(.system(size: Kitsch.s(15), weight: .bold))
                            .opacity(0.5)
                    }
                    .padding(18)
                    .stickerCard(Kitsch.card, rotation: -0.8)

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
                    .padding(.vertical, 10)
                    .stickerCard(Kitsch.card, rotation: 0.6, cornerRadius: 16)

                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L.themeLabel)
                                .font(.system(size: Kitsch.s(14), weight: .black))
                            Picker(L.themeLabel, selection: $store.theme) {
                                ForEach(AppTheme.allCases, id: \.self) { theme in
                                    Text(L.themeName(theme)).tag(theme)
                                }
                            }
                            .pickerStyle(.segmented)
                            Text(L.regionLabel)
                                .font(.system(size: Kitsch.s(14), weight: .black))
                            Picker(L.regionLabel, selection: $store.region) {
                                ForEach(Region.allCases, id: \.self) { region in
                                    Text(region.label).tag(region)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        Toggle(isOn: $store.isSecret) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L.secretTitle)
                                    .font(.system(size: Kitsch.s(14), weight: .black))
                                Text(L.secretDesc)
                                    .font(.system(size: Kitsch.s(11), weight: .bold))
                                    .opacity(0.5)
                            }
                        }
                    }
                    .tint(Kitsch.pink)
                    .padding(18)
                    .stickerCard(Kitsch.card, rotation: -0.5, cornerRadius: 16)

                    VStack(spacing: 10) {
                        HStack {
                            Text(L.workdaysThisYear)
                                .font(.system(size: Kitsch.s(14), weight: .bold))
                                .opacity(0.6)
                            Spacer()
                            Text(L.days(WorkdayCalendar.workdayCount(year: WorkdayCalendar.calendar.component(.year, from: .now))))
                                .font(.system(size: Kitsch.s(15), weight: .black))
                        }
                        HStack {
                            Text(L.dailyWage)
                                .font(.system(size: Kitsch.s(14), weight: .bold))
                                .opacity(0.6)
                            Spacer()
                            Text(store.todayWage.wonString)
                                .font(.system(size: Kitsch.s(15), weight: .black))
                        }
                        Text(L.holidayNote)
                            .font(.system(size: Kitsch.s(11), weight: .bold))
                            .opacity(0.4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(18)
                    .stickerCard(Kitsch.pastelYellow, rotation: 0.8)

                    Spacer()

                    Button {
                        if let n = Int(salaryText), n > 0 {
                            store.annualSalary = store.region.annualSalary(fromInput: n)
                        }
                        let cal = WorkdayCalendar.calendar
                        store.workStartMinutes = cal.component(.hour, from: workStart) * 60 + cal.component(.minute, from: workStart)
                        store.workEndMinutes = cal.component(.hour, from: workEnd) * 60 + cal.component(.minute, from: workEnd)
                        dismiss()
                    } label: {
                        Text(L.save)
                            .font(.system(size: Kitsch.s(17), weight: .black, design: Kitsch.design))
                            .foregroundStyle(Kitsch.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(StickerButtonStyle(fill: Kitsch.lime))
                }
                .foregroundStyle(Kitsch.ink)
                .padding(20)
            }
            .fontDesign(Kitsch.design)
            .navigationTitle(L.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.close) { dismiss() }
                        .tint(.black)
                }
            }
            .onAppear {
                salaryText = "\(store.region.inputValue(fromAnnual: store.annualSalary))"
                let cal = WorkdayCalendar.calendar
                let dayStart = cal.startOfDay(for: .now)
                workStart = dayStart.addingTimeInterval(TimeInterval(store.workStartMinutes * 60))
                workEnd = dayStart.addingTimeInterval(TimeInterval(store.workEndMinutes * 60))
            }
        }
        .preferredColorScheme(Kitsch.theme == .matrix ? .dark : .light)
    }
}
