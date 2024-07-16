//
//  File.swift
//  
//
//  Created by Mark Powell on 6/26/24.
//

import Foundation
import Combine

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
            self.recomputeTimelineWidthForScale()
        }
    }
//    private var timelinesChangeResponder: Cancellable?

    // horizontal width of the viewport in points
    public var viewportWidth: Double = 0.0

    // offset of the ScrollView containing the timelines
    public var scrollOffset: CGPoint = .zero

    // scale of the viewport
    private(set) var viewScale: CGFloat = 4.0

    // horizontal width of the drawable timeline in points
    private(set) var timelineWidth = 0.0

    // points over hours
    public var convertDurationToWidth = 1.0

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
    public var scrollOffsetAfterZoom = 0.0 // {
//        willSet {
//            objectWillChange.send()
//        }
    //}

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
//        timelinesChangeResponder = $timelines.sink(receiveValue: { timelines in
//            var earliest = timelines.first?.earliestTime ?? .distantFuture
//            var latest = timelines.first?.latestTime ?? .distantPast
//            for timeline in timelines {
//                earliest = min(timeline.earliestTime, earliest)
//                latest = max(timeline.latestTime, latest)
//            }
//            self.earliestTime = earliest
//            self.latestTime = latest
//            self.recomputeTimelineWidthForScale()
//        })
    }

    @MainActor public func setTimelineZoom(_ zoom: Double) {
        let viewXPointOffset = -scrollOffset.x + viewportWidth * 0.5
        viewCenterTimeDeltaBeforeZoom = viewXPointOffset / convertDurationToWidth
        viewScale = min(maxZoom(), max(minZoom(), abs(zoom)))
        recomputeTimelineWidthForScale()
        let newOffset = viewCenterTimeDeltaBeforeZoom * convertDurationToWidth - viewportWidth * 0.5

        // force an update even if the newOffset is the same as the current scrollOffset
        if scrollOffsetAfterZoom == newOffset {
            scrollOffsetAfterZoom = newOffset - 0.000001
        } else {
            scrollOffsetAfterZoom = newOffset
        }
    }

    public func recomputeTimelineWidthForScale() {
        convertDurationToWidth = viewScale / 3600.0
        timelineWidth = timespan * convertDurationToWidth
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
