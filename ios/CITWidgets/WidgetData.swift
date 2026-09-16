import Foundation

enum WidgetClock {
    static var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return value
    }
    static let dayNames = ["月", "火", "水", "木", "金", "土", "日"]
    static func dayIndex(_ date: Date) -> Int { (calendar.component(.weekday, from: date) + 5) % 7 }
    static func time(_ value: String, on date: Date) -> Date? {
        let parts = value.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2, (0...23).contains(parts[0]), (0...59).contains(parts[1]) else { return nil }
        return calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: date)
    }
    static func label(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    static func updated(_ milliseconds: Double?) -> String {
        guard let value = milliseconds, value > 0 else { return "アプリを開いて更新" }
        return label(Date(timeIntervalSince1970: value / 1000), format: "M/d HH:mm") + " 更新"
    }
}

struct WidgetLesson: Decodable, Identifiable {
    let period: Int
    let endPeriod: Int
    let subject: String
    let classroom: String
    let color: String
    let startTime: String
    let endTime: String
    var id: String { "\(period)-\(subject)" }
    var periodLabel: String { endPeriod > period ? "\(period)–\(endPeriod)限" : "\(period)限" }
    var timeLabel: String { "\(startTime.isEmpty ? "--:--" : startTime)–\(endTime.isEmpty ? "--:--" : endTime)" }
    func isCurrent(at date: Date) -> Bool {
        guard let start = WidgetClock.time(startTime, on: date), let end = WidgetClock.time(endTime, on: date) else { return false }
        return start <= date && date < end
    }
}

struct WidgetTimeSlot: Decodable {
    let period: Int
    let startTime: String
    let endTime: String
    var timeLabel: String { "\(startTime.isEmpty ? "--:--" : startTime)–\(endTime.isEmpty ? "--:--" : endTime)" }
}

struct ScheduleSnapshot: Decodable {
    var schemaVersion: Int? = nil
    var hasSchedule: Bool? = nil
    var scheduleTitle: String? = nil
    var updatedAt: Double? = nil
    var timeSlots: [WidgetTimeSlot]? = nil
    var monday: [WidgetLesson]? = nil
    var tuesday: [WidgetLesson]? = nil
    var wednesday: [WidgetLesson]? = nil
    var thursday: [WidgetLesson]? = nil
    var friday: [WidgetLesson]? = nil
    var saturday: [WidgetLesson]? = nil
    var days: [[WidgetLesson]] { [monday ?? [], tuesday ?? [], wednesday ?? [], thursday ?? [], friday ?? [], saturday ?? []] }
    var available: Bool { schemaVersion == 2 && hasSchedule == true }
    func timeSlot(for period: Int) -> WidgetTimeSlot {
        if let slot = timeSlots?.first(where: { $0.period == period }) { return slot }
        // Old snapshots only know a lecture's outer boundaries. Never invent
        // custom intermediate times; opening the app supplies all ten periods.
        let lessons = days.flatMap { $0 }
        return WidgetTimeSlot(period: period,
            startTime: lessons.first(where: { $0.period == period })?.startTime ?? "",
            endTime: lessons.first(where: { $0.endPeriod == period })?.endTime ?? "")
    }
    func classes(on date: Date) -> [WidgetLesson] {
        let day = WidgetClock.dayIndex(date)
        return available && day < days.count ? days[day].sorted { $0.period < $1.period } : []
    }
    static var sample: ScheduleSnapshot {
        let lesson = WidgetLesson(period: 2, endPeriod: 3, subject: "情報システム演習", classroom: "津田沼 7号館", color: "#2563EB", startTime: "10:00", endTime: "11:50")
        return ScheduleSnapshot(schemaVersion: 2, hasSchedule: true, scheduleTitle: "後期の時間割", updatedAt: Date().timeIntervalSince1970 * 1000,
            timeSlots: (1...10).map { WidgetTimeSlot(period: $0, startTime: String(format: "%02d:00", $0 + 8), endTime: $0 == 3 ? "11:50" : String(format: "%02d:00", $0 + 9)) },
            monday: [lesson], tuesday: [lesson], wednesday: [lesson], thursday: [lesson], friday: [lesson], saturday: [])
    }
}

struct WidgetDeparture: Decodable {
    let time: String
    let note: String
    let departureAt: Double
    var date: Date { Date(timeIntervalSince1970: departureAt / 1000) }
}
struct WidgetBusRoute: Decodable, Identifiable {
    let name: String
    let departures: [WidgetDeparture]
    var id: String { name }
    func next(after date: Date) -> WidgetDeparture? { departures.filter { $0.date > date }.min { $0.date < $1.date } }
}
struct BusSnapshot: Decodable {
    var schemaVersion: Int? = nil
    var updatedAt: Double? = nil
    var expiresAt: Double? = nil
    var routes: [WidgetBusRoute]? = nil
    func isFresh(at date: Date) -> Bool { schemaVersion == 2 && (expiresAt ?? 0) > date.timeIntervalSince1970 * 1000 }
}

enum WidgetStore {
    static let appGroup = "group.com.masatomurai.citapp"
    static func read<T: Decodable>(_ key: String, fallback: T) -> T {
        guard let value = UserDefaults(suiteName: appGroup)?.string(forKey: key),
              let data = value.data(using: .utf8), let decoded = try? JSONDecoder().decode(T.self, from: data) else { return fallback }
        return decoded
    }
    static func schedule() -> ScheduleSnapshot { read("weekly_full_schedule", fallback: ScheduleSnapshot()) }
    static func bus() -> BusSnapshot { read("bus_realtime", fallback: BusSnapshot()) }
}
