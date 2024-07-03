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
    
    // horizontal width of the drawable timeline in points
    @Published public var timelineWidth = 0.0
    
    // scale of time spans on screen
    @Published public var timeZoom = TimelineViewModel.defaultZoom
    
    // points over hours
    @Published public var convertDurationToWidth = 1.0
    
    // earliest time in the event data
    @Published public var earliestTime: Date = .now

    // latest time in the event data
    @Published public var latestTime: Date = .now.addingTimeInterval(86400)

    let twoWeeksInSeconds = 86400.0*14
    let tenMinutesInSeconds = 600.0
    public static let defaultZoom = 4.0

    public init(
        timelines: [TimelineEvents],
        timelineWidth: Double = 0.0,
        timeZoom: Double = TimelineViewModel.defaultZoom,
        convertDurationToWidth: Double = 1.0,
        earliestTime: Date = .now,
        latestTime: Date = .now.addingTimeInterval(86400)
    ) {
        self.timelines = timelines
        self.timelineWidth = timelineWidth
        self.timeZoom = timeZoom
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
        timeZoom = max(zoom, 0.01)
        recomputeWidth()
    }

    // maximum zoom is ten minutes to span the entire width
    public func maxZoom(_ frameWidth: Double) -> Double {
        return frameWidth / tenMinutesInSeconds * 3600.0
    }

    // minimum zoom is 2 weeks to span the entire width, or the data timespan if it is less than 2 weeks
    public func minZoom(_ frameWidth: Double) -> Double {
        return min(frameWidth / twoWeeksInSeconds * 3600.0, initialZoom(frameWidth))
    }

    public func minOffset(_ frameWidth: Double) -> Double {
//        return -timelineWidth + frameWidth * 0.5
        return -timelineWidth + frameWidth
    }

    public func maxOffset(_ frameWidth: Double) -> Double {
//        return frameWidth * 0.5
        return 0
    }

    public var timespan: TimeInterval {
        latestTime.timeIntervalSinceReferenceDate - earliestTime.timeIntervalSinceReferenceDate
    }

    public func recomputeWidth() {
        convertDurationToWidth = timeZoom / 3600.0
        timelineWidth = timespan * convertDurationToWidth
    }

    public func initialZoom(_ frameWidth: Double) -> Double {
        let delta = min(latestTime.timeIntervalSince(earliestTime), twoWeeksInSeconds)
        return frameWidth / delta * 3600.0
    }
}
