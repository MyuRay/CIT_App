import SwiftUI
import WidgetKit

struct ScheduleEntry: TimelineEntry {
    let date: Date
    let snapshot: ScheduleSnapshot
}
struct ScheduleTimeline: TimelineProvider {
    func placeholder(in context: Context) -> ScheduleEntry { ScheduleEntry(date: Date(), snapshot: .sample) }
    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        completion(ScheduleEntry(date: Date(), snapshot: context.isPreview ? .sample : WidgetStore.schedule()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        let now = Date()
        let snapshot = WidgetStore.schedule()
        let start = WidgetClock.calendar.startOfDay(for: now)
        var dates: Set<Date> = [now]
        // Prepare a full week of day changes so the widget keeps advancing
        // even if iOS delays a timeline reload for several days.
        for offset in 0...7 {
            guard let day = WidgetClock.calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            if day > now { dates.insert(day) }
            for lesson in snapshot.classes(on: day) {
                for time in [lesson.startTime, lesson.endTime] {
                    if let date = WidgetClock.time(time, on: day), date > now { dates.insert(date) }
                }
            }
        }
        let entries = dates.sorted().map { ScheduleEntry(date: $0, snapshot: snapshot) }
        let tomorrow = WidgetClock.calendar.date(byAdding: .day, value: 1, to: start) ?? now.addingTimeInterval(86400)
        completion(Timeline(entries: entries, policy: .after(tomorrow)))
    }
}
struct BusEntry: TimelineEntry {
    let date: Date
    let snapshot: BusSnapshot
}
struct BusTimeline: TimelineProvider {
    func placeholder(in context: Context) -> BusEntry { BusEntry(date: Date(), snapshot: BusSnapshot()) }
    func getSnapshot(in context: Context, completion: @escaping (BusEntry) -> Void) { completion(BusEntry(date: Date(), snapshot: WidgetStore.bus())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<BusEntry>) -> Void) {
        let now = Date()
        let snapshot = WidgetStore.bus()
        var dates: Set<Date> = [now]
        if snapshot.isFresh(at: now) {
            for route in snapshot.routes ?? [] {
                for departure in route.departures where departure.date > now { dates.insert(departure.date) }
            }
            if let expiry = snapshot.expiresAt { dates.insert(Date(timeIntervalSince1970: expiry / 1000)) }
        }
        let entries = dates.sorted().map { BusEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(60 * 60))))
    }
}

private struct WidgetSurface: ViewModifier {
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(for: .widget) { Color(UIColor.systemBackground) }
        } else {
            content.padding(16).background(Color(UIColor.systemBackground))
        }
    }
}
private struct WidgetHeading: View {
    let title: String
    let icon: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(.blue)
            Text(title).font(.subheadline).fontWeight(.bold).lineLimit(1)
            Spacer(minLength: 0)
        }
    }
}
private struct EmptyWidget: View {
    let message: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(message).font(.subheadline).fontWeight(.medium)
            Text("タップしてアプリを開く").font(.caption).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
private func lessonColor(_ hex: String) -> Color {
    let value = UInt64(hex.replacingOccurrences(of: "#", with: ""), radix: 16) ?? 0x2563EB
    return Color(red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
}

struct TodayScheduleView: View {
    @Environment(\.widgetFamily) var family
    let entry: ScheduleEntry
    var body: some View {
        let classes = entry.snapshot.classes(on: entry.date)
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text("今日の時間割").font(.system(size: 12, weight: .bold)).lineLimit(1)
                Spacer(minLength: 0)
                Text(WidgetClock.label(entry.date, format: "M/d（E）"))
                    .font(.system(size: 10)).foregroundColor(.secondary).fixedSize()
            }
            if !entry.snapshot.available {
                EmptyWidget(message: "時間割を選択してください")
            } else if classes.isEmpty {
                EmptyWidget(message: "今日は授業がありません")
            } else {
                GeometryReader { geometry in
                    let columns = classes.count > 1 && geometry.size.height / CGFloat(classes.count) < 28 ? 2 : 1
                    let rows = (classes.count + columns - 1) / columns
                    let rowHeight = min(72, (geometry.size.height - CGFloat(rows - 1) * 2) / CGFloat(rows))
                    HStack(alignment: .top, spacing: 3) {
                        ForEach(0..<columns, id: \.self) { column in
                            let start = column * rows
                            let end = min(start + rows, classes.count)
                            VStack(spacing: 2) {
                                ForEach(start..<end, id: \.self) { index in
                                    TodayLessonRow(lesson: classes[index], date: entry.date, height: rowHeight)
                                }
                            }.frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                    }
                }
            }
            if family != .systemSmall {
                Text(WidgetClock.updated(entry.snapshot.updatedAt))
                    .font(.system(size: 9)).foregroundColor(.secondary).lineLimit(1)
            }
        }
        .modifier(WidgetSurface())
        .widgetURL(URL(string: "citapp://schedule?homeWidget=true"))
    }
}

private struct TodayLessonRow: View {
    let lesson: WidgetLesson
    let date: Date
    let height: CGFloat
    var body: some View {
        let current = lesson.isCurrent(at: date)
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 1).fill(lessonColor(lesson.color)).frame(width: 2)
            Text("\(lesson.startTime.isEmpty ? "--:--" : lesson.startTime)\n\(lesson.endTime.isEmpty ? "--:--" : lesson.endTime)")
                .font(.system(size: min(10, height * 0.40)).monospacedDigit())
                .foregroundColor(.secondary).lineLimit(2).fixedSize(horizontal: true, vertical: true)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(lesson.periodLabel) \(lesson.subject)")
                    .font(.system(size: min(13, height * 0.43), weight: .semibold)).lineLimit(1)
                if current || !lesson.classroom.isEmpty {
                    Text(current ? "授業中\(lesson.classroom.isEmpty ? "" : " · \(lesson.classroom)")" : lesson.classroom)
                        .font(.system(size: min(10, height * 0.37))).foregroundColor(.secondary).lineLimit(1)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 3).frame(height: height)
        .background(current ? Color.blue.opacity(0.12) : Color(UIColor.secondarySystemBackground))
        .cornerRadius(4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(lesson.periodLabel)、\(lesson.timeLabel)、\(lesson.subject)、\(lesson.classroom)\(current ? "、授業中" : "")")
    }
}

struct FullScheduleView: View {
    let entry: ScheduleEntry
    var body: some View {
        let days = entry.snapshot.days
        let dayCount = days[5].isEmpty ? 5 : 6
        let maxPeriod = min(10, max(5, days.flatMap { $0 }.map { $0.endPeriod }.max() ?? 5))
        VStack(alignment: .leading, spacing: 10) {
            WidgetHeading(title: entry.snapshot.scheduleTitle ?? "週間時間割", icon: "square.grid.3x3")
            if !entry.snapshot.available {
                EmptyWidget(message: "時間割を選択してください")
            } else {
                GeometryReader { geometry in
                    let rowHeight = max(12, (geometry.size.height - 22 - CGFloat(maxPeriod - 1) * 2) / CGFloat(maxPeriod))
                    HStack(alignment: .top, spacing: 3) {
                        VStack(spacing: 2) {
                            Text(" ").frame(height: 20)
                            ForEach(1...maxPeriod, id: \.self) { period in
                                let slot = entry.snapshot.timeSlot(for: period)
                                HStack(spacing: 2) {
                                    Text("\(period)").font(.system(size: 10, weight: .semibold)).frame(width: 12)
                                    Text("\(slot.startTime.isEmpty ? "--:--" : slot.startTime)\n\(slot.endTime.isEmpty ? "--:--" : slot.endTime)")
                                        .font(.system(size: 8).monospacedDigit()).lineLimit(2)
                                        .minimumScaleFactor(0.9)
                                }.foregroundColor(.secondary).frame(height: rowHeight)
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel("\(period)限、\(slot.timeLabel)")
                            }
                        }.frame(width: 48)
                        ForEach(0..<dayCount, id: \.self) { day in
                            VStack(spacing: 2) {
                                Text(WidgetClock.dayNames[day]).font(.caption).fontWeight(.semibold)
                                    .foregroundColor(WidgetClock.dayIndex(entry.date) == day ? .blue : .secondary).frame(height: 20)
                                ForEach(1...maxPeriod, id: \.self) { period in
                                    if let lesson = days[day].first(where: { $0.period == period }) {
                                        let span = min(maxPeriod, lesson.endPeriod) - period + 1
                                        VStack(spacing: 2) {
                                            Text(lesson.subject).font(.system(size: 10, weight: .semibold)).lineLimit(span > 1 ? 3 : 2)
                                            if span > 1 { Text(lesson.classroom).font(.system(size: 8)).lineLimit(1).foregroundColor(.secondary) }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: rowHeight * CGFloat(max(1, span)) + CGFloat(max(0, span - 1)) * 2)
                                        .background(lessonColor(lesson.color).opacity(0.18)).cornerRadius(5)
                                    } else if !days[day].contains(where: { $0.period < period && $0.endPeriod >= period }) {
                                        RoundedRectangle(cornerRadius: 5).fill(Color.secondary.opacity(0.06)).frame(height: rowHeight)
                                    }
                                }
                            }.frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            Text(WidgetClock.updated(entry.snapshot.updatedAt) + " · タップで時間割へ").font(.caption2).foregroundColor(.secondary).lineLimit(1)
        }
        .modifier(WidgetSurface())
        .widgetURL(URL(string: "citapp://schedule?homeWidget=true"))
    }
}

struct BusScheduleView: View {
    @Environment(\.widgetFamily) var family
    let entry: BusEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetHeading(title: "学バス · 次の便", icon: "bus")
            if !entry.snapshot.isFresh(at: entry.date) {
                EmptyWidget(message: "時刻表を更新してください")
            } else if (entry.snapshot.routes ?? []).isEmpty {
                EmptyWidget(message: "本日の運行予定なし")
            } else {
                ForEach(Array((entry.snapshot.routes ?? []).prefix(family == .systemSmall ? 1 : 2))) { route in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(route.name).font(.caption).foregroundColor(.secondary).lineLimit(1)
                        if let next = route.next(after: entry.date) {
                            Text(next.time + " 発").font(.title3).fontWeight(.bold)
                        } else { Text("本日の運行は終了").font(.subheadline) }
                    }
                }
                Spacer(minLength: 0)
            }
            Text(WidgetClock.updated(entry.snapshot.updatedAt)).font(.caption2).foregroundColor(.secondary).lineLimit(1)
        }
        .modifier(WidgetSurface())
        .widgetURL(URL(string: "citapp://bus?homeWidget=true"))
    }
}

struct TodayScheduleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayScheduleWidgetProvider", provider: ScheduleTimeline()) { TodayScheduleView(entry: $0) }
            .configurationDisplayName("今日の時間割").description("終了した授業も含め、今日の全授業・時刻・教室を表示します。")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
struct FullScheduleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "FullScheduleWidgetProvider", provider: ScheduleTimeline()) { FullScheduleView(entry: $0) }
            .configurationDisplayName("週間時間割").description("各時限の開始・終了時刻と、1週間の講義を表示します。")
            .supportedFamilies([.systemLarge])
    }
}
struct BusScheduleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BusRealtimeWidgetProvider", provider: BusTimeline()) { BusScheduleView(entry: $0) }
            .configurationDisplayName("学バス").description("優先キャンパスからの次の便と更新日時を表示します。")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}
@main
struct CITWidgetsBundle: WidgetBundle {
    var body: some Widget { TodayScheduleWidget(); FullScheduleWidget(); BusScheduleWidget() }
}

struct CITWidgetsPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            TodayScheduleView(entry: ScheduleEntry(date: Date(), snapshot: .sample)).previewContext(WidgetPreviewContext(family: .systemMedium))
            FullScheduleView(entry: ScheduleEntry(date: Date(), snapshot: .sample)).previewContext(WidgetPreviewContext(family: .systemLarge))
            FullScheduleView(entry: ScheduleEntry(date: Date(), snapshot: .sample)).preferredColorScheme(.dark).previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
