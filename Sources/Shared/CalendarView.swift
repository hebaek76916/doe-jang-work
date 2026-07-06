import SwiftUI

// MARK: - 달력 그리드 (iOS·macOS 공용)

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
                        .font(.system(size: Kitsch.s(12), weight: .black))
                        .foregroundStyle(symbol == "일" ? Kitsch.pink : symbol == "토" ? Kitsch.blue : Kitsch.ink.opacity(0.45))
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
                        .strokeBorder(Kitsch.ink, lineWidth: 2)
                }
                VStack(spacing: 2) {
                    Text("\(day)")
                        .font(.system(size: Kitsch.s(11), weight: .heavy))
                        .foregroundStyle(isWorkday ? Kitsch.ink : Kitsch.ink.opacity(0.25))
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
            .font(.system(size: Kitsch.s(10), weight: .black))
            .foregroundStyle(Kitsch.stampText)
            .frame(width: 30, height: 30)
            .background {
                ZStack {
                    if Kitsch.theme == .kitsch {
                        Circle().fill(.black).offset(x: 2, y: 2.5)
                    }
                    Circle().fill(Kitsch.pink)
                    Circle().strokeBorder(Kitsch.theme == .kitsch ? .black : .clear, lineWidth: 2)
                }
            }
            .rotationEffect(.degrees(Kitsch.tilt(-14)))
    }
}
