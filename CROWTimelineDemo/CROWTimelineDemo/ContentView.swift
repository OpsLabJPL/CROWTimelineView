//
//  ContentView.swift
//  CROWTimelineDemo
//
//  Created by Mark Powell on 6/20/24.
//

import SwiftUI
import CROWTimelineView

struct ContentView: View {
    @EnvironmentObject var time: Time
    @State private var viewModel = TimelineViewModel(timelines: [])
    @State private var selectedTime = TimeSelection()
    @State private var showDatePicker = false
    @State private var navigateToDate = Time.shared.getSimulatedTime(for: .now)
    @State private var selectedTimelineEvent: TimelineEvent?
    @State private var showSelectedEvent = false
    
    var body: some View {
        NavigationStack {
            HStack {
                TimelineVStack(viewModel: viewModel, timeSelection: selectedTime, selectedTimelineEvent: $selectedTimelineEvent)
                    .task {
                        loadSampleEvents()
                    }
                    .toolbar {
                        timeZoneMenuButton
                        datePickerButton
                        autoScrollToNowButton
                        zoomInButton
                        zoomOutButton
                    }
#if os(iOS)
                    .modifier(SelectedEventSheet(
                        showSelectedEvent: $showSelectedEvent,
                        selectedTimelineEvent: $selectedTimelineEvent
                    ))
#endif
                    .onChange(of: selectedTimelineEvent) { _, event in
                        // when the user taps on (or off of) an event, show it as selected
                        showSelectedEvent = event != nil
                    }
                    .onChange(of: showSelectedEvent) { _, show in
                        // when the user dismisses the sheet, set selected event to nil
                        if !show {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTimelineEvent = nil
                                // scroll imperceptibly to force a redraw for deselection feedback
                                viewModel.scrollOffset.x += 0.01
                            }
                        }
                    }
#if os(macOS)
                macSelectedEvent()
#endif
            }
        }
    }

    var timeZoneMenuButton: some View {
        Menu {
            ForEach(TimeZones.allCases, id: \.self) { timeZone in
                Button {
                    time.selectedTimeZone = timeZone
                } label: {
                    timeZoneLabel(timeZone)
                }
            }
        } label: {
            timeZoneLabel(time.selectedTimeZone)
        }
    }

    @MainActor var zoomOutButton: some View {
        // zoom out button
        Button {
            viewModel.zoomSafely(by: 0.75)
        } label: {
            Label("Zoom Out", systemImage: "minus.magnifyingglass")
        }
        .disabled(!viewModel.canZoomOut)
    }

    @MainActor var zoomInButton: some View {
        // zoom in button
        Button {
            viewModel.zoomSafely(by: 1.5)
        } label: {
            Label("Zoom In", systemImage: "plus.magnifyingglass")
        }
        .disabled(!viewModel.canZoomIn)
    }

    @MainActor var autoScrollToNowButton: some View {
        // auto scroll to now toggle button
        Button {
            viewModel.autoScrollToNow.toggle()
        } label: {
            Label(
                "Auto-scroll",
                systemImage: viewModel.autoScrollToNow ? "play.square.fill" : "play.square"
            )
        }
    }

    @MainActor var datePickerButton: some View {
        // Date picker popover toggle
        Button {
            showDatePicker.toggle()
        } label: {
            Label("Go to date", systemImage: "clock")
        }
        .popover(isPresented: $showDatePicker) {
            datePickerPopover
        }
    }

    @MainActor var datePickerPopover: some View {
        VStack {
            Button {
                viewModel.goToDate = Time.shared.getSimulatedTime(for: .now)
                showDatePicker = false
            } label: {
                Label("Go to Now", systemImage: "clock")
            }
            .buttonStyle(.bordered)
            DatePicker(
                selection: $navigateToDate,
                in: viewModel.earliestTime...viewModel.latestTime,
                displayedComponents: .date
            ) {
                Text("Go to date")
            }
        }
        .onChange(of: navigateToDate) { _, date in
            viewModel.goToDate = date
#if os(iOS)
            showDatePicker = false
#endif
        }
        .padding()
#if os(iOS)
        .presentationCompactAdaptation(.popover)
#endif
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

    func loadSampleEvents() {
        let timelineList = Bundle.main.decode(TimelineList.self, from: "timelineEvents.json")
        viewModel.timelines = timelineList.events
        viewModel.setInitialZoom = true
    }

    @ViewBuilder func timeZoneLabel(_ timeZone: TimeZones) -> some View {
        if let flag = timeZone.flag {
            let text = "\(flag) \(timeZone.rawValue)"
            Text(text)
        } else {
            Text(timeZone.rawValue)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(Time.shared)
}
