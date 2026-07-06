import SwiftUI

struct MenuPopover: View {
    @Bindable var store: StampStore
    @State private var showSettings = false
    @State private var showCalendar = false
    @State private var peeking = false
    @State private var displayedMonth = WorkdayCalendar.calendar.startOfDay(for: .now)

    /// 시크릿 모드 + 꾹 누르는 동안(peek)은 잠깐 해제
    private var secret: Bool { store.isSecret && !peeking }

    private var cal: Calendar { WorkdayCalendar.calendar }
    private var year: Int { cal.component(.year, from: .now) }
    private var month: Int { cal.component(.month, from: .now) }
    private var displayedYear: Int { cal.component(.year, from: displayedMonth) }
    private var displayedMonthNum: Int { cal.component(.month, from: displayedMonth) }

    var body: some View {
        Group {
            if store.annualSalary <= 0 {
                MacOnboarding(store: store)
            } else if showSettings {
                MacSettings(store: store, onDone: { showSettings = false })
            } else {
                dashboard
            }
        }
        .frame(width: 300)
        .padding(18)
        .background(Kitsch.cream)
        .fontDesign(Kitsch.design)
        // .window 스타일이 콘텐츠 높이를 시스템 기본으로 잘라 스크롤이 생기는 걸 막는다.
        // fixedSize로 팝오버가 콘텐츠 실제 높이만큼 늘어나게 한다.
        .fixedSize(horizontal: false, vertical: true)
        // 테마 토글 시 정적 팔레트를 쓰는 뷰까지 전부 다시 그린다
        .id("\(store.theme.rawValue)-\(store.region.rawValue)")
    }

    private var dashboard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Text(L.appTitle)
                    .font(.system(size: Kitsch.s(18), weight: .black, design: Kitsch.design))
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Text("⚙️")
                        .font(.system(size: Kitsch.s(13)))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(StickerButtonStyle(fill: Kitsch.card, cornerRadius: 10))
                Button {
                    confirmQuit()
                } label: {
                    Text(L.quit)
                        .font(.system(size: Kitsch.s(11), weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(StickerButtonStyle(fill: Kitsch.card, cornerRadius: 10))
            }

            // 오늘 벌이 라이브 카드
            TimelineView(.periodic(from: .now, by: 1)) { context in
                liveCard(at: context.date)
            }

            // 이번 달 누적
            HStack(spacing: 10) {
                statChip(title: L.todayWageChip, value: store.todayWage.wonString(secret: secret), fill: Kitsch.card)
                statChip(title: L.monthChip, value: store.earned(year: year, month: month).wonString(secret: secret), fill: Kitsch.pastelPurple)
            }

            // 도장 버튼
            let stampedToday = store.isStamped(.now)
            Button {
                store.toggleStamp(.now)
            } label: {
                Text(stampedToday ? L.stampedToday : L.stampButtonGo)
                    .font(.system(size: Kitsch.s(15), weight: .black, design: Kitsch.design))
                    .foregroundStyle(Kitsch.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(StickerButtonStyle(fill: stampedToday ? Kitsch.pastelBlue : Kitsch.pink))
            .disabled(!store.canToggle(.now))

            // 접이식 달력
            Button {
                withAnimation(.snappy) { showCalendar.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Text(showCalendar ? L.calFold : L.calUnfold)
                        .font(.system(size: Kitsch.s(13), weight: .black, design: Kitsch.design))
                    Image(systemName: showCalendar ? "chevron.up" : "chevron.down")
                        .font(.system(size: Kitsch.s(11), weight: .black))
                }
                .foregroundStyle(Kitsch.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
            }
            .buttonStyle(StickerButtonStyle(fill: Kitsch.card, cornerRadius: 14))

            if showCalendar {
                calendarSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .foregroundStyle(Kitsch.ink)
    }

    private var calendarSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    moveMonth(-1)
                } label: {
                    Image(systemName: "chevron.left").font(.system(size: Kitsch.s(13), weight: .black)).padding(6)
                }
                .buttonStyle(StickerButtonStyle(fill: Kitsch.yellow, cornerRadius: 10))
                Spacer()
                Text(L.monthTitle(displayedYear, displayedMonthNum))
                    .font(.system(size: Kitsch.s(15), weight: .black))
                Spacer()
                Button {
                    moveMonth(1)
                } label: {
                    Image(systemName: "chevron.right").font(.system(size: Kitsch.s(13), weight: .black)).padding(6)
                }
                .buttonStyle(StickerButtonStyle(fill: Kitsch.yellow, cornerRadius: 10))
            }
            CalendarGridView(store: store, month: displayedMonth)
        }
        .foregroundStyle(Kitsch.ink)
        .padding(12)
        .stickerCard(Kitsch.card, rotation: 0.6)
    }

    private func moveMonth(_ offset: Int) {
        if let next = cal.date(byAdding: .month, value: offset, to: displayedMonth) {
            withAnimation(.snappy) { displayedMonth = next }
        }
    }

    /// 실수 종료 방지 — 한 번 더 묻고 종료
    private func confirmQuit() {
        let alert = NSAlert()
        alert.messageText = L.quitTitle
        alert.informativeText = L.quitMessage
        alert.alertStyle = .warning
        alert.addButton(withTitle: L.quit)
        alert.addButton(withTitle: L.cancel)
        if alert.runModal() == .alertFirstButtonReturn {
            NSApp.terminate(nil)
        }
    }

    @ViewBuilder
    private func liveCard(at date: Date) -> some View {
        let earned = store.earnedSoFar(at: date)
        let phase = store.phase(at: date)

        VStack(spacing: 6) {
            Text(phaseTitle(phase))
                .font(.system(size: Kitsch.s(13), weight: .heavy))
                .opacity(0.6)
            switch phase {
            case .working, .justFinished, .settled:
                Text("+\(earned.wonString(secret: secret))")
                    .font(.system(size: Kitsch.s(34), weight: .black, design: Kitsch.design))
                    .foregroundStyle(Kitsch.pink)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.4), value: earned)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    // 시크릿 모드에서 꾹 누르는 동안만 진짜 금액 표시
                    .onLongPressGesture(minimumDuration: .infinity) {} onPressingChanged: { pressing in
                        withAnimation(.snappy) { peeking = pressing }
                    }
            case .restDay:
                Text(L.restZero)
                    .font(.system(size: Kitsch.s(18), weight: .black, design: Kitsch.design))
                    .opacity(0.5)
            case .beforeWork, .commuting:
                Text(L.expectedToday(store.todayWage.wonString(secret: secret)))
                    .font(.system(size: Kitsch.s(18), weight: .black, design: Kitsch.design))
                    .opacity(0.5)
            }
            if phase == .working {
                let (start, end) = store.workInterval(on: date)
                ProgressView(value: min(max(date.timeIntervalSince(start) / end.timeIntervalSince(start), 0), 1))
                    .tint(Kitsch.pink)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .stickerCard(Kitsch.lime, rotation: -1, cornerRadius: 18)
    }

    private func phaseTitle(_ phase: WorkPhase) -> String {
        switch phase {
        case .restDay: L.restTitle + " 🧘"
        case .beforeWork: L.beforeTitle + " 🛌"
        case .commuting: L.commuteTitle + " 🏃"
        case .working: L.workingTitle + " 💸"
        case .justFinished: L.doneTitle + " 🍻"
        case .settled: L.overtimePhase
        }
    }

    private func statChip(title: String, value: String, fill: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: Kitsch.s(11), weight: .bold))
                .opacity(0.55)
            Text(value)
                .font(.system(size: Kitsch.s(14), weight: .black))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .stickerCard(fill, cornerRadius: 14)
    }
}

/// 연봉·근무시간 미설정 시 팝오버에서 바로 입력
struct MacOnboarding: View {
    @Bindable var store: StampStore
    @State private var salaryText = ""
    @State private var workStart = defaultTime(hour: 9)
    @State private var workEnd = defaultTime(hour: 18)

    private static func defaultTime(hour: Int) -> Date {
        WorkdayCalendar.calendar.date(from: DateComponents(hour: hour)) ?? .now
    }

    private var salaryManwon: Int { Int(salaryText) ?? 0 }

    var body: some View {
        VStack(spacing: 14) {
            Text("💰 \(L.obTitle)")
                .font(.system(size: Kitsch.s(18), weight: .black, design: Kitsch.design))

            HStack(spacing: 6) {
                TextField(L.salaryPlaceholder, text: $salaryText)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: Kitsch.s(24), weight: .black, design: Kitsch.design))
                Text(L.salaryUnit)
                    .font(.system(size: Kitsch.s(14), weight: .black))
                    .opacity(0.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .stickerCard(Kitsch.card, cornerRadius: 14)

            HStack(spacing: 12) {
                DatePicker(L.workStart, selection: $workStart, displayedComponents: .hourAndMinute)
                DatePicker(L.workEnd, selection: $workEnd, displayedComponents: .hourAndMinute)
            }
            .font(.system(size: Kitsch.s(12), weight: .bold))
            .datePickerStyle(.field)

            Button {
                let cal = WorkdayCalendar.calendar
                store.workStartMinutes = cal.component(.hour, from: workStart) * 60 + cal.component(.minute, from: workStart)
                store.workEndMinutes = cal.component(.hour, from: workEnd) * 60 + cal.component(.minute, from: workEnd)
                store.annualSalary = store.region.annualSalary(fromInput: salaryManwon)
            } label: {
                Text(L.startButton)
                    .font(.system(size: Kitsch.s(15), weight: .black, design: Kitsch.design))
                    .foregroundStyle(Kitsch.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(StickerButtonStyle(fill: Kitsch.pink))
            .disabled(salaryManwon <= 0)
            .opacity(salaryManwon > 0 ? 1 : 0.5)
        }
        .foregroundStyle(Kitsch.ink)
    }
}

/// 대시보드에서 ⚙️로 진입 — 연봉·출퇴근 시각 수정
struct MacSettings: View {
    @Bindable var store: StampStore
    let onDone: () -> Void

    @State private var salaryText = ""
    @State private var workStart = Date.now
    @State private var workEnd = Date.now

    private var salaryManwon: Int { Int(salaryText) ?? 0 }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("⚙️ \(L.settingsTitle)")
                    .font(.system(size: Kitsch.s(18), weight: .black, design: Kitsch.design))
                Spacer()
            }

            HStack(spacing: 6) {
                Text(L.salaryLabel)
                    .font(.system(size: Kitsch.s(13), weight: .black))
                    .opacity(0.5)
                TextField(L.salaryPlaceholder, text: $salaryText)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: Kitsch.s(22), weight: .black, design: Kitsch.design))
                Text(L.salaryUnit)
                    .font(.system(size: Kitsch.s(13), weight: .black))
                    .opacity(0.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .stickerCard(Kitsch.card, cornerRadius: 14)

            HStack(spacing: 12) {
                DatePicker(L.workStart, selection: $workStart, displayedComponents: .hourAndMinute)
                DatePicker(L.workEnd, selection: $workEnd, displayedComponents: .hourAndMinute)
            }
            .font(.system(size: Kitsch.s(12), weight: .bold))
            .datePickerStyle(.field)

            VStack(alignment: .leading, spacing: 10) {
                Picker(L.themeLabel, selection: $store.theme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(L.themeName(theme)).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Picker(L.regionLabel, selection: $store.region) {
                    ForEach(Region.allCases, id: \.self) { region in
                        Text(region.flag).tag(region)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Toggle(isOn: $store.isSecret) {
                    Text(L.secretDescShort)
                        .font(.system(size: Kitsch.s(12), weight: .bold))
                }
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            .tint(Kitsch.pink)
            .padding(12)
            .stickerCard(Kitsch.card, cornerRadius: 14)

            Text("\(L.dailyWage) \(store.todayWage.wonString)")
                .font(.system(size: Kitsch.s(11), weight: .bold))
                .opacity(0.45)

            HStack(spacing: 10) {
                Button {
                    onDone()
                } label: {
                    Text(L.cancel)
                        .font(.system(size: Kitsch.s(14), weight: .black, design: Kitsch.design))
                        .foregroundStyle(Kitsch.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(StickerButtonStyle(fill: Kitsch.card, cornerRadius: 14))

                Button {
                    let cal = WorkdayCalendar.calendar
                    store.workStartMinutes = cal.component(.hour, from: workStart) * 60 + cal.component(.minute, from: workStart)
                    store.workEndMinutes = cal.component(.hour, from: workEnd) * 60 + cal.component(.minute, from: workEnd)
                    if salaryManwon > 0 { store.annualSalary = store.region.annualSalary(fromInput: salaryManwon) }
                    onDone()
                } label: {
                    Text(L.save)
                        .font(.system(size: Kitsch.s(14), weight: .black, design: Kitsch.design))
                        .foregroundStyle(Kitsch.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(StickerButtonStyle(fill: Kitsch.lime, cornerRadius: 14))
                .disabled(salaryManwon <= 0)
                .opacity(salaryManwon > 0 ? 1 : 0.5)
            }
        }
        .foregroundStyle(Kitsch.ink)
        .onAppear {
            salaryText = "\(store.region.inputValue(fromAnnual: store.annualSalary))"
            let cal = WorkdayCalendar.calendar
            let dayStart = cal.startOfDay(for: .now)
            workStart = dayStart.addingTimeInterval(TimeInterval(store.workStartMinutes * 60))
            workEnd = dayStart.addingTimeInterval(TimeInterval(store.workEndMinutes * 60))
        }
    }
}
