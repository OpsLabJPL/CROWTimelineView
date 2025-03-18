//
//  File.swift
//  
//
//  Created by Mark Powell on 6/26/24.
//

import Foundation

public class Time: ObservableObject {
    public var simulationTimeDelta = 0.0
    public var targetSimulationTime = Date.now
    public var targetWallClockTime = Date.now
    @Published public var selectedTimeZone = TimeZones.utc {
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

    public let iso8601: ISO8601DateFormatter = {
        let iso = ISO8601DateFormatter()
        iso.timeZone = TimeZone(abbreviation: "UTC")
        return iso
    }()
    
    public let durationFormat: DateFormatter = {
        let format = DateFormatter()
        format.dateFormat = "hh'h'mm'm'ss's'"
        return format
    }()

    public let utcDoyFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = ""
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-DDD' 'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    public let utcDoyFormatWithT: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = ""
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-DDD'T'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    public let ravenDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-DDD'T'HH:mm:ss.SSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    public let ravenJsonDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-DDD'T'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    public let utcYMDDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    public let utcYMDmsDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    public let dayFormatter: DateFormatter = {
        let format = DateFormatter()
        format.dateFormat = "EEE dd"
        format.timeZone = TimeZone(abbreviation: "UTC")
        return format
    }()

    public let dayMonth3Year2Formatter: DateFormatter = {
        let format = DateFormatter()
        format.dateFormat = "EEE dd MMM yyyy"
        format.timeZone = TimeZone(abbreviation: "UTC")
        return format
    }()

    public let hourFormatter: DateFormatter = {
        let format = DateFormatter()
        format.dateFormat = "HH"
        format.timeZone = TimeZone(abbreviation: "UTC")
        return format
    }()

    public var calendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        return calendar
    }()

    public func getRealTime(for date: Date) -> Date {
        return Calendar.current.date(
            byAdding: .second,
            value: -1 * targetDelta(),
            to: date
        ) ?? Date.now
    }

    public func getSimulatedTime(for date: Date) -> Date {
        return Calendar.current.date(
            byAdding: .second,
            value: targetDelta(),
            to: date
        ) ?? Date.now
    }

    public func formatSimulatedTime(_ targetDate: Date) -> String {
        let simulatedTime = getSimulatedTime(for: targetDate)
        return utcDoyFormat.string(from: simulatedTime) + " UTC"
    }

    public func formatRealTime(for date: Date) -> String {
        let timezoneLabel = Time.shared.selectedTimeZone.zone.abbreviation() ?? Time.shared.selectedTimeZone.rawValue
        return utcDoyFormat.string(from: date) + " \(timezoneLabel)"
    }

    public func targetDelta() -> Int { Int(simulationTimeDelta) }

    public static func eventDate(_ dateString: String) -> Date? {
        if let doyDate = Time.shared.ravenJsonDateFormatter.date(from: dateString) {
            return doyDate
        }
        if let doyDate = Time.shared.ravenDateFormatter.date(from: dateString) {
            return doyDate
        }
        if let iso8601Date = Time.shared.utcYMDDateFormatter.date(from: dateString) {
            return iso8601Date
        }
        if let iso8601MillisDate = Time.shared.utcYMDmsDateFormatter.date(from: dateString) {
            return iso8601MillisDate
        }
        if let iso8601Date = Time.shared.iso8601.date(from: dateString) {
            return iso8601Date
        }
        return nil
    }

    public static let shared = Time()
    private init() {
    }
}
