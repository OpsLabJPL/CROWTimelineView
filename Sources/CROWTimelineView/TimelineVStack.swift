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
    @State var scrollOffset: CGPoint = .zero
    @State var gestureOffset = 0.0
    @State var gestureScale: CGFloat = 1.0
    @State var selectedTime: Date?
    @State var selectedTimelineEvent: TimelineEvent?
    @State var showSelectedEvent = false
    @State private var navigateToDate = Date.now
    @State private var showDatePicker = false
    static let timerInterval: Double = 1.0
    let timer = Timer.publish(every: timerInterval, on: .main, in: .common).autoconnect()
    @State var scrollTo: Int?

    public var body: some View {
        NavigationStack {
            GeometryReader { geom in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        // ribbon of day, hour labels at top for context
                        headerRibbons(geom)
                            .onTapGesture { location in
                                let cursorOrigin = location.x - scrollOffset.x
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
            DayAxisHeader(viewModel, scrollOffset: $scrollOffset, viewportWidth: geom.size.width)
                .background(Color.cyan.opacity(0.5))
                .frame(height: 15)
                .clipped()
                .onTapGesture(count: 2) {
                    selectedTime = nil
                    timeSelection.selectedTime = nil
                }
            HourAxisHeader(viewModel, scrollOffset: $scrollOffset, viewportWidth: geom.size.width)
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
                    if let offset = newScrollTo {
                        value.scrollTo(offset, anchor: UnitPoint(x: 0.0, y: 0.0))
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
        .onChange(of: selectedTimelineEvent) { event in
            showSelectedEvent = event != nil
        }
        .onChange(of: showSelectedEvent) { show in
            if !show {
                selectedTimelineEvent = nil
            }
        }
        .onReceive(timer) { _ in
            // TODO convert this to scrollTo
//            scrollOffset.x -= 1.0 /* second */ * viewModel.convertDurationToWidth
//            scrollTo = Int(abs(scrollOffset.x) / viewModel.convertDurationToWidth + 1.0 /* second */)
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
    }

    func scaleToFitWidth(_ geom: GeometryProxy) {
        let initialZoom = viewModel.initialZoom(geom.size.width)
        viewModel.setTimelineZoom(initialZoom)
        currentScale = initialZoom
    }

    func updateZoom(frameWidth: CGFloat) {
        let prevTimeOffset = (scrollOffset.x - frameWidth * 0.5) / viewModel.convertDurationToWidth
        let scale = gestureScale * currentScale
        viewModel.setTimelineZoom(min(viewModel.maxZoom(frameWidth), max(viewModel.minZoom(frameWidth), scale)))
        var newOffset = prevTimeOffset * viewModel.convertDurationToWidth + frameWidth * 0.5
        let minOffset = viewModel.minOffset(frameWidth)
        let maxOffset = viewModel.maxOffset(frameWidth)
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
