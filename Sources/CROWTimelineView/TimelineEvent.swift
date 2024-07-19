//
//  File.swift
//  
//
//  Created by Mark Powell on 6/20/24.
//

import Foundation
import SwiftUI

public struct TimelineEvent: Identifiable, Equatable, Codable {
    static let backgroundColorOpacity = 0.7
    static let backgroundCollapsedColorOpacity = 0.4
    static var colorCache: [String: Color] = [:]
    static var darkerColorCache: [String: Color] = [:]
    static var lighterColorCache: [String: Color] = [:]
    static var collapsedColorCache: [String: Color] = [:]

    public var name: String
    public var id: String
    public var color: String?
    public var username: String?
    public var duration: Double
    public var startUTC: Date
    public var endUTC: Date {
        startUTC.addingTimeInterval(duration)
    }
    var startTime: Date { startUTC }
    var endTime: Date { endUTC }
    var activityName: String { name }

    public init(
        name: String,
        id: String,
        color: String? = nil,
        username: String? = nil,
        duration: Double,
        startUTC: Date
    ) {
        self.name = name
        self.id = id
        self.color = color
        self.username = username
        self.duration = duration
        self.startUTC = startUTC
    }

    public static func == (lhs: TimelineEvent, rhs: TimelineEvent) -> Bool {
        lhs.id == rhs.id
    }

    static func fillColor(_ colorHex: String?) -> Color {
        guard let ravenColor = colorHex else {
            return .cyan
        }

        if let color = Self.colorCache[ravenColor] {
            return color
        }
#if os(macOS)
        if let nsColor = NSColor(hex: ravenColor) {
            let color = Color(nsColor: nsColor).opacity(Self.backgroundColorOpacity)
            Self.colorCache[ravenColor] = color
            return color
        }
#else
        if let uiColor = UIColor(hex: ravenColor) {
            let color = Color(uiColor: uiColor).opacity(Self.backgroundColorOpacity)
            Self.colorCache[ravenColor] = color
            return color
        }
#endif
        return .cyan
    }

    static func darkerColor(_ colorHex: String?) -> Color {
        guard let ravenColor = colorHex else {
            return .cyan
        }

        if let color = Self.darkerColorCache[ravenColor] {
            return color
        }
#if os(macOS)
        if let nsColor = NSColor(hex: ravenColor) {
            let color = Color(nsColor: nsColor.darker(by: 30)!).opacity(Self.backgroundColorOpacity)
            Self.darkerColorCache[ravenColor] = color
            return color
        }
#else
        if let uiColor = UIColor(hex: ravenColor)?.darker(by: 30) {
            let color = Color(uiColor: uiColor).opacity(Self.backgroundColorOpacity)
            Self.darkerColorCache[ravenColor] = color
            return color
        }
#endif
        return .cyan
    }

    static func lighterColor(_ colorHex: String?) -> Color {
        guard let ravenColor = colorHex else {
            return .cyan
        }
        if let color = Self.lighterColorCache[ravenColor] {
            return color
        }
#if os(macOS)
        if let nsColor = NSColor(hex: ravenColor) {
            let color = Color(nsColor: nsColor.lighter(by: 50)!).opacity(Self.backgroundColorOpacity)
            Self.lighterColorCache[ravenColor] = color
            return color
        }
#else
        if let uiColor = UIColor(hex: ravenColor)?.lighter(by: 50) {
            let color = Color(uiColor: uiColor).opacity(Self.backgroundColorOpacity)
            Self.lighterColorCache[ravenColor] = color
            return color
        }
#endif
        return .cyan
    }

    static func collapsedColor(_ colorHex: String?) -> Color {
        guard let ravenColor = colorHex else {
            return .cyan
        }
        if let color = Self.collapsedColorCache[ravenColor] {
            return color
        }
#if os(macOS)
        if let nsColor = NSColor(hex: ravenColor) {
            let color = Color(nsColor: nsColor.lighter(by: 50)!).opacity(Self.backgroundCollapsedColorOpacity)
            Self.collapsedColorCache[ravenColor] = color
            return color
        }
#else
        if let uiColor = UIColor(hex: ravenColor)?.lighter(by: 50) {
            let color = Color(uiColor: uiColor).opacity(Self.backgroundCollapsedColorOpacity)
            Self.collapsedColorCache[ravenColor] = color
            return color
        }
#endif
        return .cyan
    }
}
