//
//  SelectedEventSheet.swift
//  CROWTimelineDemo
//
//  Created by Mark Powell on 6/2/25.
//


//
//  SelectedEventSheet.swift
//  CROWTimelineDemo
//
//  Created by Mark Powell on 7/19/24.
//

import CROWTimelineView
import SwiftUI

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

