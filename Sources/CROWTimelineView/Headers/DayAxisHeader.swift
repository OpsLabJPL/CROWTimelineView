//
//  SwiftUIView.swift
//  
//
//  Created by Mark Powell on 6/26/24.
//

import SwiftUI

struct DayAxisHeader: View {
    @EnvironmentObject var time: Time
    @ObservedObject var viewModel: TimelineViewModel
    let viewportWidth: Double
    let maxWidthDay = 50.0

    var body: some View {
        Canvas { context, size in
            let viewXMin = 8.0
            let viewXMax = viewportWidth
            var dayStart = Time.shared.calendar.startOfDay(for: viewModel.earliestTime)
            guard var nextDayStart = Time.shared.calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                return
            }
            let dayWidth = viewModel.convertDurationToWidth * 86400
            let numDays = dayWidth > maxWidthDay ? 1 : 7
            let width = dayWidth * Double(numDays)
            let formatter = width >= 100.0 ? Time.shared.dayMonth3Year2Formatter : Time.shared.dayFormatter
            repeat {
                if dayStart >= viewModel.earliestTime {
                    let dayText = formatter.string(from: dayStart)
                    var leadingOffset = viewModel.convertDurationToWidth * (
                        dayStart.timeIntervalSince(viewModel.earliestTime)
                    ) + viewModel.currentOffset
                    let trailingOffset = viewModel.convertDurationToWidth * (
                        nextDayStart.timeIntervalSince(viewModel.earliestTime)
                    ) + viewModel.currentOffset
                    if !(trailingOffset < viewXMin || leadingOffset > viewXMax) {
                        var path = Path()
                        path.move(to: CGPoint(x: leadingOffset, y: 0))
                        path.addLine(to: CGPoint(x: leadingOffset, y: size.height))
                        context.stroke(path, with: .color(Color.primary))
                        if leadingOffset < 0 {
                            leadingOffset = 4
                        }
                        context.draw(
                            Text(dayText).font(.caption2).fontWeight(.semibold),
                            in: CGRect(
                                x: leadingOffset + 4,
                                y: 0,
                                width: trailingOffset - leadingOffset - 4,
                                height: size.height
                            )
                        )
                    }
                }
                dayStart = nextDayStart
                if let nextNextDayStart = Time.shared.calendar.date(byAdding: .day, value: numDays, to: nextDayStart) {
                    nextDayStart = nextNextDayStart
                } else {
                    break
                }
            } while dayStart < viewModel.latestTime
        }
    }

    init(_ viewModel: TimelineViewModel, viewportWidth: Double) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.viewportWidth = viewportWidth
    }
}

