// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

public struct TimelineCanvas: View {
    @Binding public var timeline: TimelineEvents
    @Binding public var scrollOffset: CGPoint
    @Binding public var selectedEvent: TimelineEvent?
    // horizontal pan position of the timeline on screen
    @Binding var currentOffset: Double
    // points over hours
    @Binding var convertDurationToWidth: Double
    @State private var eventBarTimeRects: [EventTimeRect] = []
    @State private var eventBarViewRects: [EventViewRect] = []
    @State private var waitForEventsProgressView = false
    let barHeight = 20.0
    public let viewportWidth: Double

    public var body: some View {
        ZStack {
            Canvas { context, _ in
                drawEventBarsAndText(context)
            }
            .frame(
                height: 21.0 * rowsHeight() + 10.0
            )
            .onTapGesture(coordinateSpace: .local) { location in
                for index in eventBarViewRects.indices where eventBarViewRects[index].rect.contains(location) {
                    let event = timeline.events[eventBarViewRects[index].eventIndex]
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedEvent = selectedEvent == event ? nil : event
                    }
                }
            }

            ProgressView()
                .opacity(waitForEventsProgressView ? 1 : 0)
        }
        .onChange(of: timeline.collapsed) { _ in
            updateEventViewRects()
        }
//        .onChange(of: viewModel.timeZoom) { _ in
        .onChange(of: convertDurationToWidth){ _ in
            updateEventViewRects()
        }
        .onChange(of: currentOffset) { _ in
            updateEventViewRects()
        }
        .onChange(of: timeline) { _ in
            createTimeline()
        }
        .onChange(of: timeline.earliestTime) { _ in
            createTimeline()
        }
        .task {
            createTimeline()
        }
    }

    func rowsHeight() -> Double {
        return timeline.collapsed ? 1.0 : Double(timeline.maxRows)
    }

    func drawEventBarsAndText(_ context: GraphicsContext) {
        let viewXMin = 0.0 // + scrollOffset.x
        let viewXMax = viewXMin + viewportWidth
        if timeline.collapsed {
            for eventViewRect in eventBarViewRects {
                if eventViewRect.rect.minX /* - scrollOffset.x */ > viewXMax || eventViewRect.rect.maxX /* - scrollOffset.x */ < viewXMin {
                    continue
                }
                // draw event bar desaturated
                var barPath = Path()
                barPath.addRect(eventViewRect.rect.applying(CGAffineTransform(translationX: -scrollOffset.x, y: 0)))
                context.fill(
                    barPath,
                    with: .color(eventCollapsedColor(eventViewRect.selected, eventViewRect.color))
                )
                context.stroke(barPath, with: .color(eventLighterColor(eventViewRect.selected, eventViewRect.color)))
            }
        } else { // draw event bar rectangle and text label
            for (index, eventViewRect) in eventBarViewRects.enumerated() {
                if eventViewRect.rect.minX > viewXMax || eventViewRect.rect.maxX < viewXMin {
                    continue
                }
                drawBar(context: context, eventViewRect: eventViewRect)
                var maxWidth = maxWidthUntilNextEventInRow(index)
                var originX = eventViewRect.rect.origin.x - scrollOffset.x + 4
                if originX < 0 {
                    maxWidth += originX // subtract clipped leading portion of bar width
                    originX = 4
                }
                let originY = eventViewRect.rect.origin.y - 1
                let textRect = CGRect(
                    x: originX,
                    y: originY,
                    width: maxWidth,
                    height: barHeight
                )
                if maxWidth < 10 {
                    continue
                }
                let text = context.resolve(Text(eventViewRect.name))
                context.draw(text, in: textRect)
            }
        }
    }

    func drawBar(context: GraphicsContext, eventViewRect: EventViewRect) {
        var barPath = Path()
        barPath.addRect(eventViewRect.rect.applying(CGAffineTransform(translationX: -scrollOffset.x, y: 0)))
        context.fill(
            barPath,
            with: .linearGradient(
                Gradient(colors: [
                    eventColor(eventViewRect.selected, eventViewRect.color),
                    eventLighterColor(eventViewRect.selected, eventViewRect.color)
                ]),
                startPoint: CGPoint(x: 0, y: eventViewRect.rect.origin.y),
                endPoint: CGPoint(x: 0, y: eventViewRect.rect.origin.y + barHeight)
            )
        )
        context.stroke(
            barPath,
            with: .color(eventDarkerColor(eventViewRect.selected, eventViewRect.color))
        )
    }

    func maxWidthUntilNextEventInRow(_ index: Int) -> Double {
        var width = 1000.0
        let nextEventIndex = index + timeline.maxRows
        guard nextEventIndex < eventBarViewRects.count else {
            return width
        }
        let thisEventViewRect = eventBarViewRects[index]
        let nextEventViewRect = eventBarViewRects[nextEventIndex]
        width = abs(nextEventViewRect.rect.origin.x - thisEventViewRect.rect.origin.x - 10)
        return width < 20 ? 0.01 : width
    }

    func eventColor(_ selected: Bool, _ colorHEX: String?) -> Color {
        return selected ? .yellow : TimelineEvent.fillColor(colorHEX)
    }

    func eventDarkerColor(_ selected: Bool, _ colorHEX: String?) -> Color {
        return selected ? .brown : TimelineEvent.darkerColor(colorHEX)
    }

    func eventLighterColor(_ selected: Bool, _ colorHEX: String?) -> Color {
        return selected ? .orange : TimelineEvent.lighterColor(colorHEX)
    }

    func eventCollapsedColor(_ selected: Bool, _ colorHEX: String?) -> Color {
        return selected ? .orange : TimelineEvent.collapsedColor(colorHEX)
    }

    func createTimeline() {
        guard eventBarTimeRects.count != timeline.events.count else {
            return
        }
        waitForEventsProgressView = true
        Task {
            let timeRects = createEventTimeRects()
            Task { @MainActor in
                eventBarTimeRects = timeRects
                updateEventViewRects()
                waitForEventsProgressView = false
            }
        }
    }

    // compute the time bars on a background thread off the main thread
    func createEventTimeRects() -> [EventTimeRect] {
        var yIndex = 0.0
        var eventTimeRects: [EventTimeRect] = []
        let maxRows = Double(timeline.maxRows)
        for event in timeline.events {
            let barWidth = event.duration
            let offsetFromOrigin = (
                event.startUTC.timeIntervalSinceReferenceDate -
                timeline.earliestTime.timeIntervalSinceReferenceDate
            )
            let expandedRect = CGRect(
                x: offsetFromOrigin,
                y: (barHeight + 2.0) * yIndex,
                width: barWidth,
                height: barHeight
            )
            let collapsedRect = CGRect(
                x: offsetFromOrigin,
                y: 0,
                width: barWidth,
                height: barHeight
            )
            eventTimeRects.append(
                EventTimeRect(expandedRect: expandedRect, collapsedRect: collapsedRect)
            )
            yIndex = (yIndex + 1).truncatingRemainder(dividingBy: maxRows)
        }
        return eventTimeRects
    }

    func updateEventViewRects() {
        guard timeline.events.count == eventBarTimeRects.count else {
            return
        }
        let viewXMin = 0.0
        let viewXMax = viewportWidth + viewXMin
        var viewRects: [EventViewRect] = []
        let selectedEventId = selectedEvent?.id
        let xform = CGAffineTransform(translationX: currentOffset, y: 0.0)
            .scaledBy(x: convertDurationToWidth, y: 1.0)
        if timeline.collapsed {
            for (i, event) in timeline.events.enumerated() {
                let viewBarRect = eventBarTimeRects[i].collapsedRect.applying(xform)
                viewRects.append(
                    EventViewRect(
                        eventIndex: i,
                        rect: viewBarRect,
                        name: event.name,
                        color: event.color,
                        selected: event.id == selectedEventId
                    )
                )
            }
        } else {
            for (i, event) in timeline.events.enumerated() {
                let viewBarRect = eventBarTimeRects[i].expandedRect.applying(xform)
                viewRects.append(
                    EventViewRect(
                        eventIndex: i,
                        rect: viewBarRect,
                        name: event.name,
                        color: event.color,
                        selected: event.id == selectedEventId
                    )
                )
            }
        }
        eventBarViewRects = viewRects.filter({
            $0.rect.minX <= viewXMax && $0.rect.maxX >= viewXMin
        })
    }

    public init(
        timeline: Binding<TimelineEvents>,
        scrollOffset: Binding<CGPoint>,
        selectedEvent: Binding<TimelineEvent?>,
        currentOffset: Binding<Double>,
        convertDurationToWidth: Binding<Double>,
        viewportWidth: Double
    ) {
        _timeline = Binding(projectedValue: timeline)
        _scrollOffset = Binding(projectedValue: scrollOffset)
        _selectedEvent = Binding(projectedValue: selectedEvent)
        _currentOffset = Binding(projectedValue: currentOffset)
        _convertDurationToWidth = Binding(projectedValue: convertDurationToWidth)
        self.viewportWidth = viewportWidth
    }
}

// Model an event's geometry, label and appearance in the view. These are recreated
// on the fly based on view zoom level, scroll offset, collapsed states, etc. and
// may be considered short-lived.
struct EventViewRect {
    var eventIndex: Int
    var rect: CGRect
    var name: String
    var color: String?
    var selected: Bool
}

// Model an event's temporal extent within the range between earliest time and latest 
// time. These may be considered long-lived for a given dataset.
struct EventTimeRect {
    var expandedRect: CGRect
    var collapsedRect: CGRect
}


#Preview {
    NavigationStack {
        VStack {
            Color.blue.opacity(0.2)

            TimelineCanvas(
                timeline: .constant(TimelineEvents.previewEvents()),
                scrollOffset: .constant(CGPoint(x: 0, y: 0)),
                selectedEvent: .constant(nil),
                currentOffset: .constant(0.0),
                convertDurationToWidth: .constant(0.02),
                viewportWidth: 320.0
            )

            Color.blue.opacity(0.2).frame(height: 16)

            TimelineCanvas(
                timeline: .constant(TimelineEvents.morePreviewEvents()),
                scrollOffset: .constant(CGPoint(x: 0, y: 0)),
                selectedEvent: .constant(nil),
                currentOffset: .constant(0.0),
                convertDurationToWidth: .constant(0.02),
                viewportWidth: 320.0
            )

            Color.blue.opacity(0.2)
        }
        .navigationTitle("Preview Canvas")
    }
}
