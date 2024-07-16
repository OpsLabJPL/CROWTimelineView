//
//  TimelineEvents.swift
//
//
//  Created by Mark Powell on 6/20/24.
//

import Foundation

@Observable
public class TimelineEvents: ObservableObject, Hashable, Identifiable, Equatable, Codable {
    public var id: String = UUID().uuidString
    public let name: String
    public var events: [TimelineEvent]
    public let maxRows: Int
    public var earliestTime: Date
    public var latestTime: Date
    public var collapsed: Bool
    public let ordinal: Int

    enum CodingKeys: String, CodingKey {
        case id, name, events, maxRows, earliestTime, latestTime, collapsed, ordinal
    }

    public required init(from decoder: any Decoder) throws {
        if let decoder = decoder as? JSONDecoder {
            decoder.dateDecodingStrategy = .iso8601
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.events = try container.decode([TimelineEvent].self, forKey: .events)
        self.maxRows = try container.decode(Int.self, forKey: .maxRows)
        self.earliestTime = try container.decode(Date.self, forKey: .earliestTime)
        self.latestTime = try container.decode(Date.self, forKey: .latestTime)
        self.collapsed = try container.decode(Bool.self, forKey: .collapsed)
        self.ordinal = try container.decode(Int.self, forKey: .ordinal)
    }

    public func encode(to encoder: any Encoder) throws {
        if let encoder = encoder as? JSONEncoder {
            encoder.dateEncodingStrategy = .iso8601
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(events, forKey: .events)
        try container.encode(maxRows, forKey: .maxRows)
        try container.encode(earliestTime, forKey: .earliestTime)
        try container.encode(latestTime, forKey: .latestTime)
        try container.encode(collapsed, forKey: .collapsed)
        try container.encode(ordinal, forKey: .ordinal)
    }

    public init(
        id: String = UUID().uuidString,
        name: String,
        events: [TimelineEvent],
        maxRows: Int,
        earliestTime: Date,
        latestTime: Date,
        collapsed: Bool = false,
        ordinal: Int
    ) {
        self.id = id
        self.name = name
        self.events = events
        self.maxRows = maxRows
        self.ordinal = ordinal
        self.earliestTime = earliestTime
        self.latestTime = latestTime
        self.collapsed = collapsed
    }

    public convenience init(
        name: String,
        events: [TimelineEvent],
        ordinal: Int,
        maxRows: Int = 5
    ) {
        var earliestTime = Date.distantFuture
        var latestTime = Date.distantPast

        if let firstEvent = events.first {
            earliestTime = firstEvent.startUTC
            latestTime = firstEvent.endUTC
            for event in events {
                earliestTime = min(event.startUTC, earliestTime)
                latestTime = max(event.endUTC, latestTime)
            }
        }

        self.init(
            name: name,
            events: events,
            maxRows: maxRows,
            earliestTime: earliestTime,
            latestTime: latestTime,
            ordinal: ordinal
        )
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }

    public static func == (lhs: TimelineEvents, rhs: TimelineEvents) -> Bool {
        lhs.id == rhs.id && lhs.name == lhs.name
    }

    public static func previewEvents() -> TimelineEvents {
        let startTime = Date.now
        let endTime = Date.now.addingTimeInterval(3600 * 4)
        let event1 = TimelineEvent(name: "First thing", id: UUID().uuidString, duration: 3600, startUTC: startTime)
        let event2 = TimelineEvent(name: "Second thing", id: UUID().uuidString, duration: 3600, startUTC: .now.addingTimeInterval(3600))
        let event3 = TimelineEvent(name: "Third thing", id: UUID().uuidString, duration: 3600, startUTC: .now.addingTimeInterval(3600 * 2))
        let event4 = TimelineEvent(name: "Fourth thing", id: UUID().uuidString, duration: 3600, startUTC: .now.addingTimeInterval(3600 * 3))
        let event5 = TimelineEvent(name: "Fifth thing", id: UUID().uuidString, duration: 3600, startUTC: endTime)
        let events = [ event1, event2, event3, event4, event5 ]
        return TimelineEvents(name: "Previews", events: events, maxRows: 5, earliestTime: startTime, latestTime: endTime, ordinal: 1)
    }

    public static func morePreviewEvents() -> TimelineEvents {
        let startTime = Date.now
        let endTime = Date.now.addingTimeInterval(3600 * 4)
        let event1 = TimelineEvent(name: "Sixth thing", id: UUID().uuidString, duration: 3600, startUTC: startTime)
        let event2 = TimelineEvent(name: "Seventh thing", id: UUID().uuidString, duration: 3600, startUTC: .now.addingTimeInterval(3600))
        let event3 = TimelineEvent(name: "Eighth thing", id: UUID().uuidString, duration: 3600, startUTC: .now.addingTimeInterval(3600 * 2))
        let event4 = TimelineEvent(name: "Ninth thing", id: UUID().uuidString, duration: 3600, startUTC: .now.addingTimeInterval(3600 * 3))
        let event5 = TimelineEvent(name: "Tenth thing", id: UUID().uuidString, duration: 3600, startUTC: endTime)
        let events = [ event1, event2, event3, event4, event5 ]
        return TimelineEvents(name: "More Previews", events: events, maxRows: 5, earliestTime: startTime, latestTime: endTime, ordinal: 2)
    }

}
