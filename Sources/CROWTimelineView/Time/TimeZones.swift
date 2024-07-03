//
//  File.swift
//  
//
//  Created by Mark Powell on 6/26/24.
//

import Foundation

public enum TimeZones: String, CaseIterable {
    case utc = "UTC", ist = "IST", pdt = "PDT", local = "Local"

    public var zone: TimeZone {
        switch self {
        case .utc:
            return TimeZone(abbreviation: "UTC")!
        case .ist:
            return TimeZone(abbreviation: "IST")!
        case .pdt:
            return TimeZone(abbreviation: "PDT")!
        case .local:
            return TimeZone.autoupdatingCurrent
        }
    }

    public var flag: String? {
        switch self {
        case .ist:
            return "🇮🇳"
        case .pdt:
            return "🇺🇸"
        case .local:
            return "✈️"
        case .utc:
            return "🌐"
        }
    }
}
