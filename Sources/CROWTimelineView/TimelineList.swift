//
//  File.swift
//  
//
//  Created by Mark Powell on 7/1/24.
//

import Foundation

public class TimelineList: ObservableObject, Identifiable, Equatable, Codable {
    public let id: String
    @Published public var name: String
    @Published public var events: [TimelineEvents]

    enum CodingKeys: String, CodingKey {
        case id, name, events
    }

    public init(id: String, name: String, events: [TimelineEvents]) {
        self.id = id
        self.name = name
        self.events = events
    }

    public required init(from decoder: any Decoder) throws {
        if let decoder = decoder as? JSONDecoder {
            decoder.dateDecodingStrategy = .iso8601
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.events = try container.decode([TimelineEvents].self, forKey: .events)
    }

    public func encode(to encoder: any Encoder) throws {
        if let encoder = encoder as? JSONEncoder {
            encoder.dateEncodingStrategy = .iso8601
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(events, forKey: .events)
    }

    public static func == (lhs: TimelineList, rhs: TimelineList) -> Bool {
        lhs.id == rhs.id
    }
}
