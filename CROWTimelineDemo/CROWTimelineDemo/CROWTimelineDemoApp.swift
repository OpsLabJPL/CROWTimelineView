//
//  CROWTimelineDemoApp.swift
//  CROWTimelineDemo
//
//  Created by Mark Powell on 6/20/24.
//

import SwiftUI
import CROWTimelineView

@main
struct CROWTimelineDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(Time.shared)
        }
    }
}
