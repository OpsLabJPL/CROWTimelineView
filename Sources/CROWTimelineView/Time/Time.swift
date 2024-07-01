//
//  File.swift
//  
//
//  Created by Mark Powell on 6/26/24.
//

import Foundation

class Time: ObservableObject {
    var simulationTimeDelta = 0.0
    var targetSimulationTime = Date.now
    var targetWallClockTime = Date.now
    @Published var selectedTimeZone = TimeZones.utc {
        didSet {
            utcDoyFormat.timeZone = selectedTimeZone.zone
            ravenDateFormatter.timeZone = selectedTimeZone.zone
            ravenJsonDateFormatter.timeZone = selectedTimeZone.zone
            dayFormatter.timeZone = selectedTimeZone.zone
            dayMonth3Year2Formatter.timeZone = selectedTimeZone.zone
            hourFormatter.timeZone = selectedTimeZone.zone
            calendar.timeZone = selectedTimeZone.zone
        }
    }

    let durationFormat: DateFormatter = {
        let format = DateFormatter()
        format.dateFormat = "hh'h'mm'm'ss's'"
        return format
    }()

    let utcDoyFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = ""
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-DDD' 'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    let utcDoyFormatWithT: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = ""
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-DDD'T'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    let ravenDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-DDD'T'HH:mm:ss.SSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    let ravenJsonDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-DDD'T'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    let utcYMDDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    let utcYMDmsDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    let dayFormatter: DateFormatter = {
        let format = DateFormatter()
        format.dateFormat = "EEE dd"
        format.timeZone = TimeZone(abbreviation: "UTC")
        return format
    }()

    let dayMonth3Year2Formatter: DateFormatter = {
        let format = DateFormatter()
        format.dateFormat = "EEE dd MMM yyyy"
        format.timeZone = TimeZone(abbreviation: "UTC")
        return format
    }()

    let hourFormatter: DateFormatter = {
        let format = DateFormatter()
        format.dateFormat = "HH"
        format.timeZone = TimeZone(abbreviation: "UTC")
        return format
    }()

    var calendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        return calendar
    }()

    func getRealTime(for date: Date) -> Date {
        return Calendar.current.date(
            byAdding: .second,
            value: -1 * targetDelta(),
            to: date
        ) ?? Date.now
    }

    func getSimulatedTime(for date: Date) -> Date {
        return Calendar.current.date(
            byAdding: .second,
            value: targetDelta(),
            to: date
        ) ?? Date.now
    }

    func formatSimulatedTime(_ targetDate: Date) -> String {
        let simulatedTime = getSimulatedTime(for: targetDate)
        return utcDoyFormat.string(from: simulatedTime) + " \(Time.shared.selectedTimeZone.rawValue)"
    }

    func formatRealTime(for date: Date) -> String {
        return utcDoyFormat.string(from: date) + " \(Time.shared.selectedTimeZone.rawValue)"
    }

    // TODO refactor this and remove Realm dependency
//    func setSimulatedTime(_ simTime: SimulatedTime) {
//        targetSimulationTime = simTime.simulatedTime
//        targetWallClockTime = simTime.wallClockTime
//        simulationTimeDelta = targetSimulationTime.timeIntervalSince(targetWallClockTime)
//    }

    func targetDelta() -> Int { Int(simulationTimeDelta) }

    static func eventDate(_ dateString: String) -> Date? {
        if let doyDate = Time.shared.ravenJsonDateFormatter.date(from: dateString) {
            return doyDate
        }
        if let iso8601Date = Time.shared.utcYMDDateFormatter.date(from: dateString) {
            return iso8601Date
        }
        if let iso8601MillisDate = Time.shared.utcYMDmsDateFormatter.date(from: dateString) {
            return iso8601MillisDate
        }
        return nil
    }

    static let shared = Time()
    private init() {
    }
}
