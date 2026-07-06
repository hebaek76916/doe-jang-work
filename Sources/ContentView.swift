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
            .id(store.isFormal)
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

    // MARK: - 실시간 벌이 카드

    /// 근무 단계에 따라 초 단위로 갱신되는 오늘의 상태 카드
    private var liveCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let phase = store.phase(at: context.date)
            let earned = store.earnedSoFar(at: context.date)

            Group {
                switch phase {
                case .restDay:
                    liveCardBody(emoji: "🧘", title: "오늘은 무급 힐링", subtitle: "쉬는 것도 일이다", fill: Kitsch.pastelBlue, rotation: 0.8)
                case .beforeWork:
                    liveCardBody(emoji: "🛌", title: "아직 출근 전", subtitle: "\(store.workStartMinutes.hhmmString)부터 돈이 오릅니다", fill: .white, rotation: -0.6)
                case .commuting:
                    liveCardBody(emoji: "🏃", title: "돈 벌러 가는 중", subtitle: "\(store.workStartMinutes.hhmmString)부터 카운트 시작!", fill: Kitsch.pastelYellow, rotation: -1)
                case .working:
                    workingCard(earned: earned, at: context.date)
                case .justFinished:
                    liveCardBody(emoji: "🍻", title: "오늘 돈 다 벌었다!", subtitle: "+\(earned.wonString(secret: secret)) — 수고했다 진짜", fill: Kitsch.lime, rotation: -1.2)
                case .settled:
                    liveCardBody(emoji: "🤑", title: store.isStamped(context.date) ? "오늘 진짜 벌었다" : "돈은 벌었는데 도장을 안 찍음 👀", subtitle: "+\(earned.wonString(secret: secret)) 확정", fill: Kitsch.pastelPurple, rotation: 0.6)
                }
            }
        }
    }

    private func liveCardBody(emoji: String, title: String, subtitle: String, fill: Color, rotation: Double) -> some View {
        HStack(spacing: 12) {
            Text(emoji).font(.system(size: 30))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .black))
                Text(subtitle)
                    .font(.system(size: 12, weight: .bold))
                    .opacity(0.55)
            }
            Spacer()
        }
        .foregroundStyle(.black)
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
                Text("💸 지금 벌고 있는 중")
                    .font(.system(size: 14, weight: .black))
                Spacer()
                Text("퇴근까지 \(remaining / 3600):\(String(format: "%02d", remaining % 3600 / 60)):\(String(format: "%02d", remaining % 60))")
                    .font(.system(size: 12, weight: .black))
                    .monospacedDigit()
                    .opacity(0.55)
            }
            Text("+\(earned.wonString(secret: secret))")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(Kitsch.pink)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.4), value: earned)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white)
                    Capsule().fill(Kitsch.pink)
                        .frame(width: max(geo.size.width * progress, 12))
                    Capsule().strokeBorder(.black, lineWidth: 2)
                }
            }
            .frame(height: 14)
        }
        .foregroundStyle(.black)
        .padding(16)
        .stickerCard(Kitsch.pastelYellow, rotation: -1, cornerRadius: 18)
    }

    // MARK: - 누적 요약

    private var summaryCard: some View {
        VStack(spacing: 14) {
            Text("이번 달 모은 돈 ✨")
                .font(.system(size: 15, weight: .heavy))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .stickerCard(Kitsch.yellow, rotation: -2, cornerRadius: 999)

            Text(store.earned(year: displayedYear, month: displayedMonthNumber).wonString(secret: secret))
                .font(.system(size: 42, weight: .black, design: .rounded))
                .contentTransition(.numericText())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                // 시크릿 모드에서 꾹 누르는 동안만 진짜 금액 표시
                .onLongPressGesture(minimumDuration: .infinity) {} onPressingChanged: { pressing in
                    withAnimation(.snappy) { peeking = pressing }
                }

            Text("도장 \(store.stampCount(year: displayedYear, month: displayedMonthNumber))개 = 순도 100% 내 돈 🤑")
                .font(.system(size: 13, weight: .bold))
                .opacity(0.65)

            HStack(spacing: 10) {
                statChip(title: "하루 일급", value: store.dailyWage(year: displayedYear).wonString(secret: secret), fill: .white, rotation: 1.5)
                statChip(title: "올해 누적", value: store.earned(year: displayedYear).wonString(secret: secret), fill: Kitsch.pastelPurple, rotation: -1)
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
                ? "오늘 +\(store.todayWage.wonString(secret: secret)) 순삭 🤑"
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

                    HStack(spacing: 14) {
                        HStack(spacing: 2) {
                            Text("출근")
                                .font(.system(size: 14, weight: .black))
                            DatePicker("", selection: $workStart, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        HStack(spacing: 2) {
                            Text("퇴근")
                                .font(.system(size: 14, weight: .black))
                            DatePicker("", selection: $workEnd, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .stickerCard(.white, rotation: 0.6, cornerRadius: 16)

                    VStack(spacing: 12) {
                        Toggle(isOn: $store.isFormal) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("포멀 모드 👔")
                                    .font(.system(size: 14, weight: .black))
                                Text("회사에서 안 튀는 차분한 디자인")
                                    .font(.system(size: 11, weight: .bold))
                                    .opacity(0.5)
                            }
                        }
                        Toggle(isOn: $store.isSecret) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("시크릿 모드 🕶️")
                                    .font(.system(size: 14, weight: .black))
                                Text("금액 끝 3자리만 표시 — 큰 금액은 꾹 눌러서 확인")
                                    .font(.system(size: 11, weight: .bold))
                                    .opacity(0.5)
                            }
                        }
                    }
                    .tint(Kitsch.pink)
                    .padding(18)
                    .stickerCard(.white, rotation: -0.5, cornerRadius: 16)

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
                        let cal = WorkdayCalendar.calendar
                        store.workStartMinutes = cal.component(.hour, from: workStart) * 60 + cal.component(.minute, from: workStart)
                        store.workEndMinutes = cal.component(.hour, from: workEnd) * 60 + cal.component(.minute, from: workEnd)
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
            .onAppear {
                salaryText = "\(store.annualSalary / 10_000)"
                let cal = WorkdayCalendar.calendar
                let dayStart = cal.startOfDay(for: .now)
                workStart = dayStart.addingTimeInterval(TimeInterval(store.workStartMinutes * 60))
                workEnd = dayStart.addingTimeInterval(TimeInterval(store.workEndMinutes * 60))
            }
        }
        .preferredColorScheme(.light)
    }
}
