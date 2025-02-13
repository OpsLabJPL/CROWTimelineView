//
//  File.swift
//  
//
//  Created by Mark Powell on 6/26/24.
//

import Foundation

public enum TimeZones: String, CaseIterable {
    case utc = "UTC", ist = "IST", pacific = "Pacific", local = "Local"

    public var zone: TimeZone {
        switch self {
        case .utc:
            return TimeZone(abbreviation: "UTC")!
        case .ist:
            return TimeZone(abbreviation: "IST")!
        case .pacific:
            return TimeZone(identifier: "America/Los_Angeles")!
        case .local:
            return TimeZone.autoupdatingCurrent
        }
    }

    public var flag: String? {
        switch self {
        case .ist:
            return "🇮🇳"
        case .pacific:
            return "🇺🇸"
        case .local:
            return "✈️"
        case .utc:
            return "🌐"
        }
    }
}
