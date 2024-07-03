//
//  HourAxisHeader.swift
//  CROWTimelineDemo
//
//  Created by Mark Powell on 6/26/24.
//

import SwiftUI

struct HourAxisHeader: View {
    @EnvironmentObject var time: Time
    @ObservedObject var viewModel: TimelineViewModel
    @Binding var scrollOffset: CGPoint
    let viewportWidth: Double
    let maxWidthHour = 15.0

    var body: some View {
        Canvas { context, size in
            let viewXMin = 0.0
            let viewXMax = viewportWidth
            var hourStart = Time.shared.calendar.startOfDay(for: viewModel.earliestTime)
            let numHours = (viewModel.convertDurationToWidth * 3600) > maxWidthHour ? 1 : 8
            let displayHourTextLabel = (viewModel.convertDurationToWidth * 28800) >= maxWidthHour
            // this is for CROW-
            //            var bgPath = Path()
            //            bgPath.move(to: CGPoint(x: 0, y: 0))
            //            bgPath.addRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
            //            let gradient = Gradient(colors: hourColors)
            //            context.fill(
            //                bgPath,
            //                with: .linearGradient(gradient,
            //                startPoint: CGPoint(x: 0,
            //                y: 0),
            //                endPoint: CGPoint(x: size.width,
            //                y: 0))
            //            )

            repeat {
                if hourStart >= viewModel.earliestTime {
                    let hourText = Time.shared.hourFormatter.string(from: hourStart)
                    let xOffset = viewModel.convertDurationToWidth * (
                        hourStart.timeIntervalSince(viewModel.earliestTime)
                    ) + scrollOffset.x
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

                if let nextHourStart = Time.shared.calendar.date(byAdding: .hour, value: numHours, to: hourStart) {
                    hourStart = nextHourStart
                } else {
                    break
                }
            } while hourStart < viewModel.latestTime
        }
    }

    init(_ viewModel: TimelineViewModel, scrollOffset: Binding<CGPoint>, viewportWidth: Double) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _scrollOffset = Binding(projectedValue: scrollOffset)
        self.viewportWidth = viewportWidth
    }

    let hourColors: [Color] = [
        Color.color(hex: "#cce0ff"),
        Color.color(hex: "#b3d1ff"),
        Color.color(hex: "#99c2ff"),
        Color.color(hex: "#80b3ff"),
        Color.color(hex: "#66a3ff"),
        Color.color(hex: "#4d94ff"),
        Color.color(hex: "#3385ff"),
        Color.color(hex: "#ffe6e6"),
        Color.color(hex: "#ffcccc"),
        Color.color(hex: "#ffb3b3"),
        Color.color(hex: "#ff9999"),
        Color.color(hex: "#ff8080"),
        Color.color(hex: "#ff6666"),
        Color.color(hex: "#ff4d4d"),
        Color.color(hex: "#ff3333"),
        Color.color(hex: "#ecf9ec"),
        Color.color(hex: "#d8f3d8"),
        Color.color(hex: "#c5edc5"),
        Color.color(hex: "#b1e7b1"),
        Color.color(hex: "#9ee09e"),
        Color.color(hex: "#8bda8b"),
        Color.color(hex: "#77d477"),
        Color.color(hex: "#64ce64"),
        Color.color(hex: "#e6f0ff")
    ]
}
