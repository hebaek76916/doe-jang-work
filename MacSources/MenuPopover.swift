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
        .fontDesign(.rounded)
        // .window 스타일이 콘텐츠 높이를 시스템 기본으로 잘라 스크롤이 생기는 걸 막는다.
        // fixedSize로 팝오버가 콘텐츠 실제 높이만큼 늘어나게 한다.
        .fixedSize(horizontal: false, vertical: true)
        // 테마 토글 시 정적 팔레트를 쓰는 뷰까지 전부 다시 그린다
        .id(store.isFormal)
    }

    private var dashboard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Text("💸 출근도장")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Text("⚙️")
                        .font(.system(size: 13))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(StickerButtonStyle(fill: .white, cornerRadius: 10))
                Button {
                    confirmQuit()
                } label: {
                    Text("종료")
                        .font(.system(size: 11, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(StickerButtonStyle(fill: .white, cornerRadius: 10))
            }

            // 오늘 벌이 라이브 카드
            TimelineView(.periodic(from: .now, by: 1)) { context in
                liveCard(at: context.date)
            }

            // 이번 달 누적
            HStack(spacing: 10) {
                statChip(title: "오늘 일급", value: store.todayWage.wonString(secret: secret), fill: .white)
                statChip(title: "이번 달", value: store.earned(year: year, month: month).wonString(secret: secret), fill: Kitsch.pastelPurple)
            }

            // 도장 버튼
            let stampedToday = store.isStamped(.now)
            Button {
                store.toggleStamp(.now)
            } label: {
                Text(stampedToday ? "오늘 도장 찍음 ✅" : "출근 도장 쾅 💥")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
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
                    Text(showCalendar ? "달력 접기" : "달력 펼치기 📅")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                    Image(systemName: showCalendar ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .black))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
            }
            .buttonStyle(StickerButtonStyle(fill: .white, cornerRadius: 14))

            if showCalendar {
                calendarSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .foregroundStyle(.black)
    }

    private var calendarSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    moveMonth(-1)
                } label: {
                    Image(systemName: "chevron.left").font(.system(size: 13, weight: .black)).padding(6)
                }
                .buttonStyle(StickerButtonStyle(fill: Kitsch.yellow, cornerRadius: 10))
                Spacer()
                Text("\(String(displayedYear))년 \(displayedMonthNum)월")
                    .font(.system(size: 15, weight: .black))
                Spacer()
                Button {
                    moveMonth(1)
                } label: {
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .black)).padding(6)
                }
                .buttonStyle(StickerButtonStyle(fill: Kitsch.yellow, cornerRadius: 10))
            }
            CalendarGridView(store: store, month: displayedMonth)
        }
        .foregroundStyle(.black)
        .padding(12)
        .stickerCard(.white, rotation: 0.6)
    }

    private func moveMonth(_ offset: Int) {
        if let next = cal.date(byAdding: .month, value: offset, to: displayedMonth) {
            withAnimation(.snappy) { displayedMonth = next }
        }
    }

    /// 실수 종료 방지 — 한 번 더 묻고 종료
    private func confirmQuit() {
        let alert = NSAlert()
        alert.messageText = "출근도장을 종료할까요?"
        alert.informativeText = "종료하면 메뉴바 티커가 사라져요. 돈은 계속 벌리는데 안 보임 🥲"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "종료")
        alert.addButton(withTitle: "취소")
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
                .font(.system(size: 13, weight: .heavy))
                .opacity(0.6)
            switch phase {
            case .working, .justFinished, .settled:
                Text("+\(earned.wonString(secret: secret))")
                    .font(.system(size: 34, weight: .black, design: .rounded))
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
                Text("0원도 힐링이면 OK")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .opacity(0.5)
            case .beforeWork, .commuting:
                Text("오늘 \(store.todayWage.wonString(secret: secret)) 예정")
                    .font(.system(size: 18, weight: .black, design: .rounded))
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
        case .restDay: "오늘은 무급 힐링 🧘"
        case .beforeWork: "아직 출근 전 🛌"
        case .commuting: "돈 벌러 가는 중 🏃"
        case .working: "지금 벌고 있는 중 💸"
        case .justFinished: "다 벌었다, 수고했다 🍻"
        case .settled: "정시 이후 = 무료봉사 🫠"
        }
    }

    private func statChip(title: String, value: String, fill: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .opacity(0.55)
            Text(value)
                .font(.system(size: 14, weight: .black))
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
            Text("💰 연봉 얼마 받음?")
                .font(.system(size: 18, weight: .black, design: .rounded))

            HStack(spacing: 6) {
                TextField("1000", text: $salaryText)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                Text("만원")
                    .font(.system(size: 14, weight: .black))
                    .opacity(0.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .stickerCard(.white, cornerRadius: 14)

            HStack(spacing: 12) {
                DatePicker("출근", selection: $workStart, displayedComponents: .hourAndMinute)
                DatePicker("퇴근", selection: $workEnd, displayedComponents: .hourAndMinute)
            }
            .font(.system(size: 12, weight: .bold))
            .datePickerStyle(.field)

            Button {
                let cal = WorkdayCalendar.calendar
                store.workStartMinutes = cal.component(.hour, from: workStart) * 60 + cal.component(.minute, from: workStart)
                store.workEndMinutes = cal.component(.hour, from: workEnd) * 60 + cal.component(.minute, from: workEnd)
                store.annualSalary = salaryManwon * 10_000
            } label: {
                Text("시작하기 🚀")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(StickerButtonStyle(fill: Kitsch.pink))
            .disabled(salaryManwon <= 0)
            .opacity(salaryManwon > 0 ? 1 : 0.5)
        }
        .foregroundStyle(.black)
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
                Text("⚙️ 설정")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                Spacer()
            }

            HStack(spacing: 6) {
                Text("연봉")
                    .font(.system(size: 13, weight: .black))
                    .opacity(0.5)
                TextField("1000", text: $salaryText)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                Text("만원")
                    .font(.system(size: 13, weight: .black))
                    .opacity(0.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .stickerCard(.white, cornerRadius: 14)

            HStack(spacing: 12) {
                DatePicker("출근", selection: $workStart, displayedComponents: .hourAndMinute)
                DatePicker("퇴근", selection: $workEnd, displayedComponents: .hourAndMinute)
            }
            .font(.system(size: 12, weight: .bold))
            .datePickerStyle(.field)

            VStack(spacing: 8) {
                Toggle(isOn: $store.isFormal) {
                    Text("포멀 모드 👔 — 회사에서 안 튀는 디자인")
                        .font(.system(size: 12, weight: .bold))
                }
                Toggle(isOn: $store.isSecret) {
                    Text("시크릿 모드 🕶️ — 금액 끝 3자리만 표시")
                        .font(.system(size: 12, weight: .bold))
                }
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .tint(Kitsch.pink)
            .padding(12)
            .stickerCard(.white, cornerRadius: 14)

            Text("주말·공휴일 빼고 하루 \(store.todayWage.wonString)")
                .font(.system(size: 11, weight: .bold))
                .opacity(0.45)

            HStack(spacing: 10) {
                Button {
                    onDone()
                } label: {
                    Text("취소")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(StickerButtonStyle(fill: .white, cornerRadius: 14))

                Button {
                    let cal = WorkdayCalendar.calendar
                    store.workStartMinutes = cal.component(.hour, from: workStart) * 60 + cal.component(.minute, from: workStart)
                    store.workEndMinutes = cal.component(.hour, from: workEnd) * 60 + cal.component(.minute, from: workEnd)
                    if salaryManwon > 0 { store.annualSalary = salaryManwon * 10_000 }
                    onDone()
                } label: {
                    Text("저장 💾")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(StickerButtonStyle(fill: Kitsch.lime, cornerRadius: 14))
                .disabled(salaryManwon <= 0)
                .opacity(salaryManwon > 0 ? 1 : 0.5)
            }
        }
        .foregroundStyle(.black)
        .onAppear {
            salaryText = "\(store.annualSalary / 10_000)"
            let cal = WorkdayCalendar.calendar
            let dayStart = cal.startOfDay(for: .now)
            workStart = dayStart.addingTimeInterval(TimeInterval(store.workStartMinutes * 60))
            workEnd = dayStart.addingTimeInterval(TimeInterval(store.workEndMinutes * 60))
        }
    }
}
