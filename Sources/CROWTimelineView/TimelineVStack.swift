//
//  TimelineVStack.swift
//  CROWTimelineDemo
//
//  Created by Mark Powell on 6/26/24.
//

import SwiftUI

public struct TimelineVStack: View {
    @EnvironmentObject var timeSelection: TimeSelection
    @ObservedObject var viewModel: TimelineViewModel
    @State private var simNow = Time.shared.getSimulatedTime(for: Date.now)
    @State private var scaleWhenMagnifyBegins: CGFloat?
    @State var scrollOffset: CGPoint = .zero
    @State var gestureOffset = 0.0
    @State var selectedTime: Date?
    @State var selectedTimelineEvent: TimelineEvent?
    @State var showSelectedEvent = false
    @State private var navigateToDate = Date.now
    @State private var showDatePicker = false
    static let timerInterval: Double = 1.0
    let timer = Timer.publish(every: timerInterval, on: .main, in: .common).autoconnect()
    @State var scrollTo: Int?
    let timelineViewId = 55555

    public var body: some View {
        GeometryReader { geom in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    // ribbon of day, hour labels at top for context
                    headerRibbons()
                        .onTapGesture { location in
                            let cursorOrigin = location.x - scrollOffset.x
                            let timeOffset = cursorOrigin / viewModel.convertDurationToWidth
                            selectedTime = viewModel.earliestTime.addingTimeInterval(timeOffset)
                            timeSelection.selectedTime = selectedTime
                        }

                    timelineChartStack()
                }
#if os(macOS)
                macSelectedEvent()
#endif
            }
            .navigationTitle("offset: \(Int(scrollOffset.x)) w: \(Int(viewModel.timelineWidth))")
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        if let scaleWhenMagnifyBegins {
                            viewModel.viewScale = scaleWhenMagnifyBegins * value.magnification
                        } else {
                            scaleWhenMagnifyBegins = viewModel.viewScale
                            viewModel.viewScale = viewModel.viewScale * value.magnification
                        }
                        print("viewScale: \(viewModel.viewScale), magnify: \(value.magnification)")
                    }
                    .onEnded { value in
                        Task {
                            scaleWhenMagnifyBegins = nil
                        }
                    }
            )

            .onChange(of: geom.size.width) { _, newWidth in
                viewModel.viewportWidth = newWidth
            }
            .onChange(of: viewModel.viewScale) { _, _ in
                updateZoom()
            }
            .onChange(of: viewModel.setInitialZoom) { _, setInitialZoom in
                if setInitialZoom {
                    scaleToFitWidth()
                    viewModel.setInitialZoom = false
                }
            }
        }
#if os(iOS)
        .modifier(SelectedEventSheet(
            showSelectedEvent: $showSelectedEvent,
            selectedTimelineEvent: $selectedTimelineEvent
        ))
#endif
    }

    @ViewBuilder func headerRibbons() -> some View {
        Group {
            DayAxisHeader(viewModel, scrollOffset: $scrollOffset)
                .background(Color.cyan.opacity(0.5))
                .frame(height: 15)
                .clipped()
                .onTapGesture(count: 2) {
                    selectedTime = nil
                    timeSelection.selectedTime = nil
                }
            HourAxisHeader(viewModel, scrollOffset: $scrollOffset)
                .background(Color.cyan.opacity(0.5))
                .frame(height: 15)
                .clipped()
                .onTapGesture(count: 2) {
                    selectedTime = nil
                    timeSelection.selectedTime = nil
                }
        }
    }

    @ViewBuilder func timelineChartStack() -> some View {
        // stack of event charts
        ZStack {
            ScrollViewReader { scrollProxy in
                ScrollViewWithOffsetTracking([.horizontal, .vertical], showsIndicators: true, onScroll: updateScrollOffset) {
                    ZStack {
                        VStack(alignment: .leading) {
                            ForEach($viewModel.timelines) { $timeline in
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(timeline.name)
                                        Spacer()
                                        Button {
                                            timeline.collapsed.toggle()
                                        } label: {
                                            Image(
                                                systemName: timeline.collapsed ? "chevron.down" : "chevron.up"
                                            )
                                        }
                                    }
                                    .systemBackgroundSectionHeader()
                                    .offset(x: -scrollOffset.x)
                                    TimelineCanvas(
                                        timeline: $timeline,
                                        scrollOffset: $scrollOffset,
                                        selectedEvent: $selectedTimelineEvent,
                                        convertDurationToWidth: $viewModel.convertDurationToWidth,
                                        viewportWidth: $viewModel.viewportWidth
                                    )
                                    .systemBackground()
                                }
                            }
                        }

                        // Make an invisible view that has the full width of the timeline and an ID to refer to in scrollProxy.scrollTo.
                        // Using a UnitPoint within this view, the scrollTo method can position the viewport wherever we tell it to.
                        let timelineWidth = viewModel.timelineWidth > 0 ? viewModel.timelineWidth : 0
                        Color.clear.frame(width: timelineWidth)
                            .id(timelineViewId)
                    }
                }
                .onChange(of: scrollTo) { _, newScrollTo in
                    if let offset = newScrollTo {
                        // the normalized scroll offset is used by UnitPoint to scroll the viewport where we ask it to go in view coordinates
                        // viewModel.timelineWidth is the denominator for normalization: the full width of the timeline at its current scale
                        let unitPointXOffset = Double(offset) / viewModel.timelineWidth
                        scrollProxy.scrollTo(timelineViewId, anchor: UnitPoint(x: unitPointXOffset, y: 0.0))
                    } else {
                        print("scrollTo nil")
                    }
                }
            }

            NowLine(viewModel: viewModel, scrollOffset: $scrollOffset, simNow: $simNow)
                .allowsHitTesting(false)
                .frame(maxHeight: .infinity)

            CursorLine(viewModel: viewModel, scrollOffset: $scrollOffset, selectedTime: $selectedTime)
                .allowsHitTesting(false)
                .frame(maxHeight: .infinity)
        }
        .clipped()
        .onChange(of: selectedTimelineEvent) { _, event in
            showSelectedEvent = event != nil
        }
        .onChange(of: showSelectedEvent) { _, show in
            if !show {
                selectedTimelineEvent = nil
            }
        }
        .onReceive(timer) { _ in
            simNow = Time.shared.getSimulatedTime(for: Date.now)
            if viewModel.autoScrollToNow {
                let deltaNow = simNow.timeIntervalSince(viewModel.earliestTime)
                let centerTimeOffset = viewModel.viewportWidth / viewModel.convertDurationToWidth * 0.5
                scrollTo = nil
                Task { @MainActor in
                    scrollTo = Int(1 + (deltaNow - centerTimeOffset) * viewModel.convertDurationToWidth)
                    print("scrollTo: \(scrollTo!)")
                }
            }
        }
        .onChange(of: viewModel.goToDate) { _, newDate in
            if let newDate {
                let timeDelta = newDate.timeIntervalSince(viewModel.earliestTime)
                let scrollOffset = timeDelta * viewModel.convertDurationToWidth - viewModel.viewportWidth * 0.5
                scrollTo = Int(scrollOffset)
                viewModel.goToDate = nil
            }
        }
    }

    /// on Mac show event detail as a right-side view
    @ViewBuilder func macSelectedEvent() -> some View {
        if selectedTimelineEvent != nil {
            VStack {
                TimelineEventDetail(event: selectedTimelineEvent!)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimelineEvent = nil
                    }
                } label: {
                    Label("Close", systemImage: "x.circle.fill")
                }
                Spacer()
            }
        }
    }
    
    func updateScrollOffset(_ offset: CGPoint) {
        self.scrollOffset = offset
    }

    func scaleToFitWidth() {
        let initialZoom = viewModel.initialZoom()
        viewModel.setTimelineZoom(initialZoom)
        viewModel.viewScale = initialZoom
    }

    @MainActor func updateZoom() {
        let viewportCenterOffset = viewModel.viewportWidth * 0.5
        print("startOffset \(scrollOffset.x)")
        let prevOffset = (scrollOffset.x - viewportCenterOffset)
        let prevTimeOffset = prevOffset / viewModel.convertDurationToWidth

        viewModel.setTimelineZoom(min(viewModel.maxZoom(), max(viewModel.minZoom(), viewModel.viewScale)))
        var newOffset = prevTimeOffset * viewModel.convertDurationToWidth + viewportCenterOffset
        print("newOffset: \(newOffset)")
        let minOffset = viewModel.minOffset()
        let maxOffset = viewModel.maxOffset()
        newOffset = max(minOffset, min(maxOffset, newOffset))
        scrollTo = Int(abs(newOffset))
    }

    func sectionCollapseIconName(_ collapsed: Bool) -> String {
        collapsed ? "chevron.down" : "chevron.up"
    }
    
    public init(viewModel: TimelineViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }
}

/// on iPhone show event detail as a bottom sheet
struct SelectedEventSheet: ViewModifier {
    @Binding var showSelectedEvent: Bool
    @Binding var selectedTimelineEvent: TimelineEvent?

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showSelectedEvent) {
                Group {
                    if let event = selectedTimelineEvent {
                        TimelineEventDetail(event: event)
                    } else {
                        Text("No event selected")
                    }
                }
                .presentationDetents([.fraction(0.35)])
                .presentationDragIndicator(.visible)
            }
    }
}

#Preview {
    let viewModel = TimelineViewModel(
        timelines: [ TimelineEvents.previewEvents() , TimelineEvents.morePreviewEvents() ]
    )
    return TimelineVStack(viewModel: viewModel)
}
