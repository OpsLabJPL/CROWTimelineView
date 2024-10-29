//
//  File.swift
//  
//
//  Created by Mark Powell on 6/26/24.
//

import Foundation
import Combine

public struct ViewportTransform: Equatable {
    // points over hours
    public var convertDurationToWidth: Double

    // set to invoke a change in scroll position
    public var scrollTo: Double?

    static public func == (lhs: ViewportTransform, rhs: ViewportTransform) -> Bool {
        lhs.convertDurationToWidth == rhs.convertDurationToWidth
        && lhs.scrollTo == rhs.scrollTo
    }
}

@Observable
public class TimelineViewModel {
    public var timelines: [TimelineEvents] = [] {
        didSet {
            var earliest = timelines.first?.earliestTime ?? .distantFuture
            var latest = timelines.first?.latestTime ?? .distantPast
            for timeline in timelines {
                earliest = min(timeline.earliestTime, earliest)
                latest = max(timeline.latestTime, latest)
            }
            self.earliestTime = earliest
            self.latestTime = latest
            Task { @MainActor in
                try await Task.sleep(nanoseconds: 100_000_000)
                let convertDurationToWidth = viewScale / 3600.0
                timelineWidth = timespan * convertDurationToWidth
                viewXform = ViewportTransform(convertDurationToWidth: convertDurationToWidth, scrollTo: nil)
                setTimelineZoom(initialZoom())
            }
        }
    }

    public var viewXform: ViewportTransform

    // horizontal width of the viewport in points
    public var viewportWidth: Double = 0.0

    // offset of the ScrollView containing the timelines
    public var scrollOffset: CGPoint = .zero

    // scale of the viewport
    private(set) var viewScale: CGFloat = 4.0

    // horizontal width of the drawable timeline in points
    private(set) var timelineWidth = 0.0

    // earliest time in the event data
    public var earliestTime: Date = .now

    // latest time in the event data
    public var latestTime: Date = .now.addingTimeInterval(86400)

    // request the timeline set itself to its initial zoom level
    public var setInitialZoom = false

    // Continuously scroll the timeline to the current time
    public var autoScrollToNow = false

    // When set, scroll the timeline to center the view on this date, then set to nil
    public var goToDate: Date?

    // the duration since earliestTime of the center of the viewport
    private(set) var viewCenterTimeDeltaBeforeZoom: Double = 0.0

    // the new ScrollView offset position after the user zooms the timeline
    public var scrollOffsetAfterZoom = 0.0

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
        self.viewXform = ViewportTransform(
            convertDurationToWidth: convertDurationToWidth,
            scrollTo: nil
        )
        self.earliestTime = earliestTime
        self.latestTime = latestTime
    }

    @MainActor public func setTimelineZoom(_ zoom: Double) {
        let viewXPointOffset = -scrollOffset.x + viewportWidth * 0.5
        viewCenterTimeDeltaBeforeZoom = viewXPointOffset / viewXform.convertDurationToWidth
        viewScale = min(maxZoom(), max(minZoom(), abs(zoom)))
        viewXform.convertDurationToWidth = viewScale / 3600.0
        timelineWidth = timespan * viewXform.convertDurationToWidth
        let newOffset = viewCenterTimeDeltaBeforeZoom * viewXform.convertDurationToWidth - viewportWidth * 0.5
        viewXform = ViewportTransform(
            convertDurationToWidth: viewXform.convertDurationToWidth,
            scrollTo: newOffset
        )
    }

    @MainActor public func zoomSafely(by scaleMultiplier: Double) {
        if scaleMultiplier > 1 {
            setTimelineZoom(min(viewScale * scaleMultiplier, maxZoom()))
        } else if scaleMultiplier > 0 && scaleMultiplier < 1 {
            setTimelineZoom(max(viewScale * scaleMultiplier, minZoom()))
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

    public func initialZoom() -> Double {
        let delta = min(latestTime.timeIntervalSince(earliestTime), twoWeeksInSeconds)
        return viewportWidth / delta * 3600.0
    }
}
