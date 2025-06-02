//
//  TimelineEventDetail.swift
//  CROWTimelineDemo
//
//  Created by Mark Powell on 6/2/25.
//


//
//  TimelineEventDetail.swift
//  CROW-iOS
//
//  Created by Mark Powell on 7/10/23.
//

import CROWTimelineView
import SwiftUI

struct TimelineEventDetail: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    let event: TimelineEvent

    var body: some View {
        VStack {
            Form {
                LabeledContent("Name") {
                    Text(event.name)
                }
                LabeledContent("Start") {
                    Text("\(Time.shared.utcDoyFormat.string(from: event.startUTC)) \(Time.shared.selectedTimeZone.rawValue)")
                }
                LabeledContent("End") {
                    Text("\(Time.shared.utcDoyFormat.string(from: event.endUTC)) \(Time.shared.selectedTimeZone.rawValue)")
                }
                LabeledContent("Duration") {
                    Text(duration(event))
                }
            }
        }
    }

    func duration(_ event: TimelineEvent) -> String {
        let seconds = Duration.seconds(
            event.endUTC.timeIntervalSince(event.startUTC)
        )
        let hms = seconds.formatted(.units(allowed: [.hours, .minutes, .seconds], width: .wide))
        return hms
    }
}

struct TimelineEventDetail_Previews: PreviewProvider {
    static let crowPreviewEvent: TimelineEvent = {
        let event = TimelineEvent(name: "One Hour Activity", id: UUID().uuidString, duration: 3600.0, startUTC: Date.now)
        return event
    }()

    static var previews: some View {
        TimelineEventDetail(event: crowPreviewEvent)
    }
}
