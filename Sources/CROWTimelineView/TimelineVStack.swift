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
    @State var currentScale: CGFloat = 4.0
    @State var gestureOffset = 0.0
    @State var gestureScale: CGFloat = 1.0
    @State var selectedTime: Date?
    @State var selectedTimelineEvent: TimelineEvent?
    @State var showSelectedEvent = false
    @State private var navigateToDate = Date.now
    @State private var showDatePicker = false
    static let timerInterval: Double = 1.0
    let timer = Timer.publish(every: timerInterval, on: .main, in: .common).autoconnect()
    @State var scrollOffset: CGPoint = .zero
    @State var scrollTo: Int?

    public var body: some View {
        NavigationStack {
            GeometryReader { geom in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        // ribbon of day, hour labels at top for context
                        headerRibbons(geom)
                            .onTapGesture { location in
                                let cursorOrigin = location.x - viewModel.currentOffset
                                let timeOffset = cursorOrigin / viewModel.convertDurationToWidth
                                selectedTime = viewModel.earliestTime.addingTimeInterval(timeOffset)
                                timeSelection.selectedTime = selectedTime
                            }
                        timelineChartStack(geom)
                    }
#if os(macOS)
                    macSelectedEvent()
#endif
                }
                .navigationTitle("offset: \(Int(scrollOffset.x)) w: \(Int(viewModel.timelineWidth))")
                .modifier(
                    ZoomModifier(
                        $gestureScale,
                        $currentScale,
                        minZoom: viewModel.minZoom(geom.size.width),
                        maxZoom: viewModel.maxZoom(geom.size.width)
                    )
                )
                .onChange(of: gestureScale) { _ in
                    updateZoom(frameWidth: geom.size.width)
                }
                .onChange(of: currentScale) { _ in
                    updateZoom(frameWidth: geom.size.width)
                }
                .task {
                    if viewModel.timeZoom == TimelineViewModel.defaultZoom {
                        scaleToFitWidth(geom)
                    }
                }
            }
        }
#if os(iOS)
        .modifier(SelectedEventSheet(
            showSelectedEvent: $showSelectedEvent,
            selectedTimelineEvent: $selectedTimelineEvent
        ))
#endif
//        .task {
//            navigateToDate = viewModel.earliestTime
//        }
    }

    @ViewBuilder func headerRibbons(_ geom: GeometryProxy) -> some View {
        Group {
            DayAxisHeader(viewModel, viewportWidth: geom.size.width)
                .background(Color.cyan.opacity(0.5))
                .frame(height: 15)
                .clipped()
                .onTapGesture(count: 2) {
                    selectedTime = nil
                    timeSelection.selectedTime = nil
                }
            HourAxisHeader(viewModel, viewportWidth: geom.size.width)
                .background(Color.cyan.opacity(0.5))
                .frame(height: 15)
                .clipped()
                .onTapGesture(count: 2) {
                    selectedTime = nil
                    timeSelection.selectedTime = nil
                }
        }
    }

    @ViewBuilder func timelineChartStack(_ geom: GeometryProxy) -> some View {
        // stack of event charts
        ZStack {
            ScrollViewReader { value in
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
                                        currentOffset: $viewModel.currentOffset,
                                        convertDurationToWidth: $viewModel.convertDurationToWidth,
                                        viewportWidth: geom.size.width
                                    )
                                    .systemBackground()
                                }
                            }
                        }
                        LazyHStack(alignment: .center, spacing: 0) {
                            if viewModel.timelineWidth <= 0 {
                                Color.clear
                            } else {
                                ForEach(1...Int(viewModel.timelineWidth), id: \.self) { index in
                                    Color.clear.frame(width: 1)
                                        .id(index)
                                }
                            }
                        }
                    }
                }
                .onChange(of: scrollTo) { newScrollTo in
                    if newScrollTo == nil {
                        print("scrollTo nil")
                    }
                    if let offset = newScrollTo {
                        print("scrollTo \(offset)")
                        value.scrollTo(1, anchor: UnitPoint(x: CGFloat(offset), y: CGFloat(0)))
                        scrollTo = nil
                    }
                }
            }

            NowLine(viewModel: viewModel, simNow: $simNow)
                .allowsHitTesting(false)
                .frame(maxHeight: .infinity)

            CursorLine(viewModel: viewModel, selectedTime: $selectedTime)
                .allowsHitTesting(false)
                .frame(maxHeight: .infinity)
        }
        .clipped()
        .onChange(of: selectedTimelineEvent) { event in
            showSelectedEvent = event != nil
        }
        .onChange(of: showSelectedEvent) { show in
            if !show {
                selectedTimelineEvent = nil
            }
        }
        .onReceive(timer) { _ in
            viewModel.currentOffset -= 1.0 /* second */ * viewModel.convertDurationToWidth
            simNow = Time.shared.getSimulatedTime(for: Date.now)
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
        viewModel.currentOffset = offset.x
        /*
         TODO:
         currentOffset is positive increasing right, 0 at the middle of the view (x == timelineWidth * 0.5)
         scrollOffset (offset.x) is negative increasing right, 0 at the left edge of the view
         Shouldn't we convert this here to simplify the hell out of everything?
         */
        // viewModel.currentOffset = -offset.x - viewModel.timelineWidth * 0.5
    }

    func scaleToFitWidth(_ geom: GeometryProxy) {
        viewModel.setTimelineZoom(viewModel.initialZoom(geom.size.width))
    }

    func updateZoom(frameWidth: CGFloat) {
        let prevTimeOffset = (viewModel.currentOffset - frameWidth * 0.5) / viewModel.convertDurationToWidth
        let scale = gestureScale * currentScale
        viewModel.timeZoom = min(viewModel.maxZoom(frameWidth), max(viewModel.minZoom(frameWidth), scale))
        viewModel.recomputeWidth()
        let newOffset = prevTimeOffset * viewModel.convertDurationToWidth + frameWidth * 0.5
        let minOffset = viewModel.minOffset(frameWidth)
        let maxOffset = viewModel.maxOffset(frameWidth)
        viewModel.currentOffset = max(minOffset, min(maxOffset, newOffset))
        scrollTo = Int(viewModel.currentOffset + viewModel.timelineWidth * 0.5)
    }

    func sectionCollapseIconName(_ collapsed: Bool) -> String {
        collapsed ? "chevron.down" : "chevron.up"
    }
    
    public init(
        viewModel: TimelineViewModel
    ) {
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
