//
//  TimelineVStack.swift
//  CROWTimelineDemo
//
//  Created by Mark Powell on 6/26/24.
//

import OSLog
import SwiftUI

public struct TimelineVStack: View {
    @Bindable var viewModel: TimelineViewModel
    @Bindable var timeSelection: TimeSelection
    @State private var simNow = Time.shared.getSimulatedTime(for: Date.now)
    @State var selectedTime: Date?
    @Binding var selectedTimelineEvent: TimelineEvent?
    @State private var navigateToDate = Date.now
    @State private var showDatePicker = false
    static let timerInterval: Double = 1.0
    @State private var timer = Timer.publish(every: timerInterval, on: .main, in: .common).autoconnect()
    let timelineViewId = 55555
    let logger = Logger(subsystem: "TimelineView", category: "navigation")

    public var body: some View {
        GeometryReader { geom in
            VStack(alignment: .leading, spacing: 2) {
                // ribbon of day, hour labels at top for context
                headerRibbons()
                    .onTapGesture { location in
                        let cursorOrigin = location.x - viewModel.scrollOffset.x
                        let timeOffset = cursorOrigin / viewModel.viewXform.convertDurationToWidth
                        selectedTime = viewModel.earliestTime.addingTimeInterval(timeOffset)
                        timeSelection.selectedTime = selectedTime
                    }

                timelineScrollView()
            }

            // display ScrollView offset position and width for debugging and performance analysis
            // .navigationTitle("offset: \(Int(viewModel.scrollOffset.x)) w: \(Int(viewModel.timelineWidth))")
            .onChange(of: geom.size) { _, newSize in
                Task { @MainActor in
                    viewModel.viewportWidth = newSize.width
                }
            }
            .onChange(of: viewModel.setInitialZoom) { _, setInitialZoom in
                if setInitialZoom {
                    scaleToFitWidth()
                    viewModel.setInitialZoom = false
                }
            }
            .onAppear {
                // on Mac the viewportWidth can become 0 after switching projects.
                // if that happens, this will set the width and draw the view.
                if viewModel.viewportWidth == 0 {
                    viewModel.viewportWidth = geom.size.width
                }
            }
        }
    }

    @ViewBuilder func headerRibbons() -> some View {
        Group {
            DayAxisHeader(viewModel, scrollOffset: $viewModel.scrollOffset)
                .background(Color.cyan.opacity(0.5))
                .frame(height: 15)
                .clipped()
                .onTapGesture(count: 2) {
                    selectedTime = nil
                    timeSelection.selectedTime = nil
                }
            HourAxisHeader(viewModel, scrollOffset: $viewModel.scrollOffset)
                .background(Color.cyan.opacity(0.5))
                .frame(height: 15)
                .clipped()
                .onTapGesture(count: 2) {
                    selectedTime = nil
                    timeSelection.selectedTime = nil
                }
        }
    }

    @ViewBuilder func timelineScrollView() -> some View {
        // stack of event charts
        ZStack {
            ScrollViewReader { scrollProxy in
#if os(iOS)
                if #available(iOS 18, *) {
                    ScrollView([.horizontal, .vertical], showsIndicators: true) {
                        timelineChartStack(scrollProxy)
                    }
                    .onScrollGeometryChange(for: CGPoint.self) { geom in
                        geom.contentOffset
                    } action: { _, offset in
                        print("offset y: \(offset.y)")
                        viewModel.scrollOffset = CGPoint(x: -offset.x, y: offset.y)
                    }
                    .onScrollGeometryChange(for: CGSize.self) { geom in
                        geom.contentSize
                    } action: { _, size in
                        viewModel.contentSize = size
                    }
                    .onScrollGeometryChange(for: CGSize.self) { geom in
                        geom.containerSize
                    } action: { _, size in
                        viewModel.viewportSize = size
                    }
                } else {
                    ScrollViewWithOffsetTracking([.horizontal, .vertical], showsIndicators: true, onScroll: updateScrollOffset) {
                        timelineChartStack(scrollProxy)
                    }
                }
#elseif os(macOS)
                if #available(macOS 15, *) {
                    ScrollView([.horizontal, .vertical], showsIndicators: true) {
                        timelineChartStack(scrollProxy)
                    }
                    .onScrollGeometryChange(for: CGPoint.self) { geom in
                        geom.contentOffset
                    } action: { _, offset in
                        print("offset y: \(offset.y)")
                        viewModel.scrollOffset = CGPoint(x: -offset.x, y: offset.y)
                    }
                    .onScrollGeometryChange(for: CGSize.self) { geom in
                        geom.contentSize
                    } action: { _, size in
                        viewModel.contentSize = size
                    }
                    .onScrollGeometryChange(for: CGSize.self) { geom in
                        geom.containerSize
                    } action: { _, size in
                        viewModel.viewportSize = size
                    }
                } else {
                    ScrollViewWithOffsetTracking([.horizontal, .vertical], showsIndicators: true, onScroll: updateScrollOffset) {
                        timelineChartStack(scrollProxy)
                    }
                }
#endif
            }

            NowLine(viewModel: viewModel, scrollOffset: $viewModel.scrollOffset, simNow: $simNow)
                .allowsHitTesting(false)
                .frame(maxHeight: .infinity)

            CursorLine(viewModel: viewModel, scrollOffset: $viewModel.scrollOffset, selectedTime: $selectedTime)
                .allowsHitTesting(false)
                .frame(maxHeight: .infinity)
        }
        .clipped()
        .onReceive(timer) { _ in
            simNow = Time.shared.getSimulatedTime(for: Date.now)
            if viewModel.autoScrollToNow {
                let durationUntilNow = simNow.timeIntervalSince(viewModel.earliestTime)
                let newScrollTo = durationUntilNow * viewModel.viewXform.convertDurationToWidth - viewModel.viewportWidth * 0.5
                viewModel.viewXform = ViewportTransform(
                    convertDurationToWidth: viewModel.viewXform.convertDurationToWidth,
                    scrollTo: newScrollTo
                )
            }
        }
        .onChange(of: viewModel.goToDate) { _, newDate in
            if let newDate {
                let timeDelta = newDate.timeIntervalSince(viewModel.earliestTime)
                let scrollOffset = timeDelta * viewModel.viewXform.convertDurationToWidth - viewModel.viewportWidth * 0.5
                viewModel.viewXform = ViewportTransform(
                    convertDurationToWidth: viewModel.viewXform.convertDurationToWidth,
                    scrollTo: scrollOffset
                )
                viewModel.goToDate = nil
            }
        }
    }

    @ViewBuilder func timelineChartStack(_ scrollProxy: ScrollViewProxy) -> some View {
        ZStack {
            VStack(alignment: .leading) {
                ForEach(viewModel.timelines) { timeline in
                    VStack(alignment: .leading) {
                        HStack {
                            Button {
                                timeline.collapsed = !timeline.collapsed
                            } label: {
                                Image(
                                    systemName: timeline.collapsed ? "chevron.down.circle" : "chevron.up.circle"
                                )
                            }
                            Text(timeline.name)
                            Spacer()
                        }
                        .systemBackgroundSectionHeader()
                        .offset(x: -viewModel.scrollOffset.x)
                        TimelineCanvas(
                            timeline: timeline,
                            earliestTime: viewModel.earliestTime,
                            scrollOffset: $viewModel.scrollOffset,
                            selectedEvent: $selectedTimelineEvent,
                            convertDurationToWidth: viewModel.viewXform.convertDurationToWidth,
                            viewportWidth: viewModel.viewportWidth
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
                .onChange(of: viewModel.viewXform) { _, newViewXform in
                    if let offset = newViewXform.scrollTo {
                        // the normalized scroll offset is used by UnitPoint to scroll the viewport where we ask it to go in view coordinates
                        // viewModel.timelineWidth is the denominator for normalization: the full width of the timeline at its current scale
                        let unitPointXOffset = offset / (viewModel.timelineWidth - viewModel.viewportWidth)
                        let unitPointYOffset = viewModel.scrollOffset.y / (viewModel.contentSize.height - viewModel.viewportSize.height)
                        print("contentSizeHeight \(viewModel.contentSize.height)")
                        print("unitPointYOffset \(unitPointYOffset)")
                        scrollProxy.scrollTo(timelineViewId, anchor: UnitPoint ( x: unitPointXOffset, y: unitPointYOffset))
                        viewModel.scrollOffset.x = offset
                    }
                }
        }
    }
    
    func updateScrollOffset(_ offset: CGPoint) {
        viewModel.scrollOffset = offset
//        logger.debug("scrollOffset \(offset.x) width: \(viewModel.timelineWidth)")
    }

    @MainActor func scaleToFitWidth() {
        let initialZoom = viewModel.initialZoom()
        viewModel.setTimelineZoom(initialZoom)
    }

    func sectionCollapseIconName(_ collapsed: Bool) -> String {
        collapsed ? "chevron.down" : "chevron.up"
    }
    
    public init(
        viewModel: TimelineViewModel,
        timeSelection: TimeSelection,
        selectedTimelineEvent: Binding<TimelineEvent?>
    ) {
        _viewModel = Bindable(viewModel)
        _timeSelection = Bindable(timeSelection)
        _selectedTimelineEvent = Binding(projectedValue: selectedTimelineEvent)
    }
}

#Preview {
    @Previewable @State var timeSelection = TimeSelection()
    let viewModel = TimelineViewModel(
        timelines: [ TimelineEvents.previewEvents() , TimelineEvents.morePreviewEvents() ]
    )
    return TimelineVStack(
        viewModel: viewModel,
        timeSelection: timeSelection,
        selectedTimelineEvent: .constant(nil)
    )
    .environmentObject(Time.shared)
}
