import SwiftUI
import WidgetKit

@main
struct WorkStampWidgetBundle: WidgetBundle {
    var body: some Widget {
        EarningWidget()
    }
}

struct EarningWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "EarningWidget", provider: EarningProvider()) { entry in
            EarningWidgetView(entry: entry)
                .containerBackground(for: .widget) { Kitsch.cream }
        }
        .configurationDisplayName(L.widgetName)
        .description(L.widgetDesc)
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 타임라인

struct EarningEntry: TimelineEntry {
    let date: Date
    let phase: WorkPhase
    let earned: Int
    let dailyWage: Int
    let stampedToday: Bool
    let workStart: Date
    let workEnd: Date
    let hasSalary: Bool
    let secret: Bool
}

struct EarningProvider: TimelineProvider {
    func placeholder(in context: Context) -> EarningEntry {
        sampleEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (EarningEntry) -> Void) {
        completion(context.isPreview ? sampleEntry() : entry(at: .now, store: StampStore()))
    }

    /// 위젯은 초 단위 갱신이 안 되므로 근무시간 동안 분 단위 엔트리를 깔아서
    /// 금액이 계속 오르는 것처럼 보이게 한다. (진행바·카운트다운은 시스템이 초 단위로 자동 갱신)
    func getTimeline(in context: Context, completion: @escaping (Timeline<EarningEntry>) -> Void) {
        let store = StampStore()
        let now = Date.now
        let cal = WorkdayCalendar.calendar
        var entries = [entry(at: now, store: store)]

        if store.annualSalary > 0, WorkdayCalendar.isWorkday(now) {
            let (start, end) = store.workInterval(on: now)
            let boundaries = [start.addingTimeInterval(-3600), start, end, end.addingTimeInterval(2 * 3600)]
            for boundary in boundaries where boundary > now {
                entries.append(entry(at: boundary, store: store))
            }
            // 근무 중 구간: 1분 간격으로 금액 갱신
            var tick = max(start, now.addingTimeInterval(60))
            while tick < end {
                entries.append(entry(at: tick, store: store))
                tick.addTimeInterval(60)
            }
            entries.sort { $0.date < $1.date }
        }

        let tomorrow = cal.startOfDay(for: now).addingTimeInterval(24 * 3600 + 60)
        completion(Timeline(entries: entries, policy: .after(tomorrow)))
    }

    private func entry(at date: Date, store: StampStore) -> EarningEntry {
        // 위젯 프로세스의 팔레트 플래그 동기화
        Kitsch.theme = store.theme
        L.region = store.region
        let (start, end) = store.workInterval(on: date)
        return EarningEntry(
            date: date,
            phase: store.phase(at: date),
            earned: store.earnedSoFar(at: date),
            dailyWage: store.todayWage,
            stampedToday: store.isStamped(date),
            workStart: start,
            workEnd: end,
            hasSalary: store.annualSalary > 0,
            secret: store.isSecret
        )
    }

    private func sampleEntry() -> EarningEntry {
        EarningEntry(
            date: .now, phase: .working, earned: 132_450, dailyWage: 202_429,
            stampedToday: true, workStart: .now.addingTimeInterval(-4 * 3600),
            workEnd: .now.addingTimeInterval(4 * 3600), hasSalary: true, secret: false
        )
    }
}

// MARK: - 뷰

struct EarningWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: EarningEntry

    var body: some View {
        if !entry.hasSalary {
            VStack(spacing: 6) {
                Text("💼").font(.system(size: Kitsch.s(30)))
                Text(L.setupFirst)
                    .font(.system(size: Kitsch.s(13), weight: .heavy, design: Kitsch.design))
            }
            .foregroundStyle(Kitsch.ink)
        } else if family == .systemMedium {
            mediumBody
        } else {
            smallBody
        }
    }

    private var phaseEmoji: String {
        switch entry.phase {
        case .restDay: "🧘"
        case .beforeWork: "🛌"
        case .commuting: "🏃"
        case .working: "💸"
        case .justFinished: "🍻"
        case .settled: "🤑"
        }
    }

    private var phaseTitle: String {
        switch entry.phase {
        case .restDay: L.tickerRest
        case .beforeWork: L.beforeTitle
        case .commuting: L.commuteTitle
        case .working: L.workingTitle
        case .justFinished: L.doneTitle
        case .settled: entry.stampedToday ? L.settledTitleStamped : L.settledTitleNoStamp
        }
    }

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(phaseEmoji).font(.system(size: Kitsch.s(24)))
            Text(phaseTitle)
                .font(.system(size: Kitsch.s(12), weight: .heavy, design: Kitsch.design))
                .minimumScaleFactor(0.8)
            Group {
                switch entry.phase {
                case .working, .justFinished, .settled:
                    Text("+\(entry.earned.wonString(secret: entry.secret))")
                        .font(.system(size: Kitsch.s(19), weight: .black, design: Kitsch.design))
                        .foregroundStyle(Kitsch.pink)
                        .minimumScaleFactor(0.6)
                case .commuting, .beforeWork:
                    Text(L.expectedToday(entry.dailyWage.wonString(secret: entry.secret)))
                        .font(.system(size: Kitsch.s(12), weight: .bold, design: Kitsch.design))
                        .opacity(0.55)
                        .minimumScaleFactor(0.7)
                case .restDay:
                    Text(L.restZero)
                        .font(.system(size: Kitsch.s(12), weight: .bold, design: Kitsch.design))
                        .opacity(0.55)
                }
            }
            if entry.phase == .working {
                workProgressBar
            }
        }
        .lineLimit(1)
        .foregroundStyle(Kitsch.ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumBody: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(phaseEmoji).font(.system(size: Kitsch.s(30)))
                Text(phaseTitle)
                    .font(.system(size: Kitsch.s(14), weight: .heavy, design: Kitsch.design))
                    .minimumScaleFactor(0.8)
                if entry.phase == .working {
                    HStack(spacing: 4) {
                        Text(L.untilOff)
                            .font(.system(size: Kitsch.s(11), weight: .bold))
                            .opacity(0.5)
                        Text(timerInterval: entry.date...entry.workEnd, countsDown: true)
                            .font(.system(size: Kitsch.s(11), weight: .black, design: Kitsch.design))
                            .foregroundStyle(Kitsch.blue)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 6) {
                switch entry.phase {
                case .working, .justFinished, .settled:
                    Text("+\(entry.earned.wonString(secret: entry.secret))")
                        .font(.system(size: Kitsch.s(26), weight: .black, design: Kitsch.design))
                        .foregroundStyle(Kitsch.pink)
                        .minimumScaleFactor(0.5)
                case .commuting, .beforeWork:
                    Text(L.expectedToday(entry.dailyWage.wonString(secret: entry.secret)))
                        .font(.system(size: Kitsch.s(18), weight: .black, design: Kitsch.design))
                        .opacity(0.6)
                        .minimumScaleFactor(0.6)
                case .restDay:
                    Text(L.restZero)
                        .font(.system(size: Kitsch.s(14), weight: .bold, design: Kitsch.design))
                        .opacity(0.55)
                }
                if entry.phase == .working {
                    workProgressBar.frame(width: 120)
                }
            }
        }
        .lineLimit(1)
        .foregroundStyle(Kitsch.ink)
    }

    /// 시스템이 초 단위로 부드럽게 채워주는 진행바
    private var workProgressBar: some View {
        ProgressView(timerInterval: entry.workStart...entry.workEnd, countsDown: false, label: { EmptyView() }, currentValueLabel: { EmptyView() })
            .progressViewStyle(.linear)
            .tint(Kitsch.pink)
    }
}
