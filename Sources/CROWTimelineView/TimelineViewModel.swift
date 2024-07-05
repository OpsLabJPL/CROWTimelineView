//
//  File.swift
//  
//
//  Created by Mark Powell on 6/26/24.
//

import Foundation
import Combine

public class TimelineViewModel: ObservableObject {
    @Published public var timelines: [TimelineEvents] = []
    var timelinesChangeResponder: Cancellable?

    // horizontal width of the viewport in points
    @Published public var viewportWidth: Double = 0.0

    // scale of the viewport
    @Published public var viewScale: CGFloat = 4.0

    // horizontal width of the drawable timeline in points
    @Published public var timelineWidth = 0.0

    // points over hours
    @Published public var convertDurationToWidth = 1.0
    
    // earliest time in the event data
    @Published public var earliestTime: Date = .now

    // latest time in the event data
    @Published public var latestTime: Date = .now.addingTimeInterval(86400)

    // request the timeline set itself to its initial zoom level
    @Published public var setInitialZoom = false

    // Continuously scroll the timeline to the current time
    @Published public var autoScrollToNow = false

    // When set, scroll the timeline to center the view on this date, then set to nil
    @Published public var goToDate: Date?

    let twoWeeksInSeconds = 86400.0 * 14
    let thirtyMinutesInSeconds = 1800.0
    public static let defaultZoom = 1.0

    public init(
        timelines: [TimelineEvents],
        timelineWidth: Double = 0.0,
        convertDurationToWidth: Double = 1.0,
        earliestTime: Date = .now,
        latestTime: Date = .now.addingTimeInterval(86400)
    ) {
        self.timelines = timelines
        self.timelineWidth = timelineWidth
        self.convertDurationToWidth = convertDurationToWidth
        self.earliestTime = earliestTime
        self.latestTime = latestTime
        timelinesChangeResponder = $timelines.sink(receiveValue: { timelines in
            var earliest = timelines.first?.earliestTime ?? .distantFuture
            var latest = timelines.first?.latestTime ?? .distantPast
            for timeline in timelines {
                earliest = min(timeline.earliestTime, earliest)
                latest = max(timeline.latestTime, latest)
            }
            self.earliestTime = earliest
            self.latestTime = latest
            self.recomputeWidth()
        })
    }

    public func setTimelineZoom(_ zoom: Double) { 
        viewScale = abs(zoom)
        recomputeWidth()
    }

    public func zoomSafely(by scaleMultiplier: Double) {
        if scaleMultiplier > 1 {
            viewScale = min(viewScale * scaleMultiplier, maxZoom())
        } else if scaleMultiplier > 0 && scaleMultiplier < 1 {
            viewScale = max(viewScale * 0.75, minZoom())
        }
    }

    public var canZoomIn: Bool {
        viewScale < maxZoom()
    }

    public var canZoomOut: Bool {
        viewScale > minZoom()
    }

    // maximum zoom is thirty minutes to span the viewport width
    public func maxZoom() -> Double {
        return viewportWidth / thirtyMinutesInSeconds * 3600.0
    }

    // minimum zoom is 2 weeks to span the viewport width, or the data timespan if it is less than 2 weeks
    public func minZoom() -> Double {
        return min(viewportWidth / twoWeeksInSeconds * 3600.0, initialZoom())
    }

    public func minOffset() -> Double {
        return -timelineWidth + viewportWidth
    }

    public func maxOffset() -> Double {
        return 0
    }

    public var timespan: TimeInterval {
        latestTime.timeIntervalSinceReferenceDate - earliestTime.timeIntervalSinceReferenceDate
    }

    public func recomputeWidth() {
        // arbitrarily choose 400 pts as a notional display width
        // also arbitrarily choose 1 point per hour as a reference conversion multiplier
        convertDurationToWidth = viewScale / 3600.0
        timelineWidth = timespan * convertDurationToWidth
    }

    public func initialZoom() -> Double {
        let delta = min(latestTime.timeIntervalSince(earliestTime), twoWeeksInSeconds)
        return viewportWidth / delta * 3600.0
    }
}
