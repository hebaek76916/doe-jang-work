import SwiftUI

struct MenuPopover: View {
    @Bindable var store: StampStore

    private var cal: Calendar { WorkdayCalendar.calendar }
    private var year: Int { cal.component(.year, from: .now) }
    private var month: Int { cal.component(.month, from: .now) }

    var body: some View {
        Group {
            if store.annualSalary > 0 {
                dashboard
            } else {
                MacOnboarding(store: store)
            }
        }
        .frame(width: 300)
        .padding(18)
        .background(Kitsch.cream)
        .fontDesign(.rounded)
        // .window 스타일이 콘텐츠 높이를 시스템 기본으로 잘라 스크롤이 생기는 걸 막는다.
        // fixedSize로 팝오버가 콘텐츠 실제 높이만큼 늘어나게 한다.
        .fixedSize(horizontal: false, vertical: true)
    }

    private var dashboard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("💸 출근도장")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                Spacer()
                Button {
                    NSApp.terminate(nil)
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
                statChip(title: "오늘 일급", value: store.todayWage.wonString, fill: .white)
                statChip(title: "이번 달", value: store.earned(year: year, month: month).wonString, fill: Kitsch.pastelPurple)
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
        }
        .foregroundStyle(.black)
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
                Text("+\(earned.wonString)")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(Kitsch.pink)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.4), value: earned)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            case .restDay:
                Text("0원도 힐링이면 OK")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .opacity(0.5)
            case .beforeWork, .commuting:
                Text("오늘 \(store.todayWage.wonString) 예정")
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
