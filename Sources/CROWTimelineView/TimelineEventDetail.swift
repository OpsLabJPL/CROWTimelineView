//
//  TimelineEventDetail.swift
//  CROW-iOS
//
//  Created by Mark Powell on 7/10/23.
//

import SwiftUI

struct TimelineEventDetail: View {
    @EnvironmentObject var time: Time
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    let event: TimelineEvent

    var body: some View {
        VStack {
#if os(iOS)
            if let username = event.username {
                HStack {
                    Button {
                        if let url = URL(string: "jplmobile://search?term=\(username)") {
                            openURL(url)
                        }
                    } label: {
                        Label("Open in JPL Mobile", systemImage: "person.crop.circle")
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "x.circle.fill")
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
                .buttonStyle(.bordered)
                .font(.caption)
            }
#endif
            Form {
                LabeledContent("Name") {
                    Text(event.activityName)
                }
                LabeledContent("Start") {
                    Text("\(time.utcDoyFormat.string(from: event.startTime)) \(time.selectedTimeZone.rawValue)")
                }
                LabeledContent("End") {
                    Text("\(time.utcDoyFormat.string(from: event.endTime)) \(time.selectedTimeZone.rawValue)")
                }
                LabeledContent("Duration") {
                    Text(duration(event))
                }
            }
        }
    }

    func duration(_ event: TimelineEvent) -> String {
        let seconds = Duration.seconds(
            event.endTime.timeIntervalSince(event.startTime)
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
            .environmentObject(Time.shared)
    }
}
