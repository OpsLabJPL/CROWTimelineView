//
//  HourAxisHeader.swift
//  CROWTimelineDemo
//
//  Created by Mark Powell on 6/26/24.
//

import SwiftUI

struct HourAxisHeader: View {
    @EnvironmentObject var time: Time
    @Bindable var viewModel: TimelineViewModel
    let maxWidthHour = 15.0

    var body: some View {
        Canvas { context, size in
            let viewXMin = 0.0
            let viewXMax = viewModel.viewportWidth
            var hourStart = time.calendar.startOfDay(for: viewModel.earliestTime)
            let numHours = (viewModel.viewXform.convertDurationToWidth * 3600) > maxWidthHour ? 1 : 8
            let displayHourTextLabel = (viewModel.viewXform.convertDurationToWidth * 28800) >= maxWidthHour

            repeat {
                if hourStart >= viewModel.earliestTime {
                    let hourText = Time.shared.hourFormatter.string(from: hourStart)
                    let xOffset = viewModel.viewXform.convertDurationToWidth * (
                        hourStart.timeIntervalSince(viewModel.earliestTime)
                    ) + viewModel.scrollOffset.x
                    if xOffset < viewXMax && xOffset > viewXMin {
                        var path = Path()
                        path.move(to: CGPoint(x: xOffset, y: 0))
                        path.addLine(to: CGPoint(x: xOffset, y: size.height))
                        context.stroke(path, with: .color(Color.primary))
                        if displayHourTextLabel {
                            context.draw(
                                Text(hourText).font(.caption2).fontWeight(.semibold),
                                at: CGPoint(x: xOffset + 4, y: 0),
                                anchor: .topLeading
                            )
                        }
                    }
                }

                if let nextHourStart = time.calendar.date(byAdding: .hour, value: numHours, to: hourStart) {
                    hourStart = nextHourStart
                } else {
                    break
                }
            } while hourStart < viewModel.latestTime
        }
    }

    init(_ viewModel: TimelineViewModel) {
        _viewModel = Bindable(viewModel)
    }
}
