//
//  ZoomModifier.swift
//  CROWTimelineDemo
//
//  Created by Mark Powell on 6/26/24.
//

import SwiftUI

struct ZoomModifier: ViewModifier {
    @Binding var gestureScale: CGFloat
    @Binding var currentScale: CGFloat
    let minZoom: Double
    let maxZoom: Double

    func body(content: Content) -> some View {
        content
            .gesture(
                MagnificationGesture()
//                    .onChanged { val in
//                        let delta = val / gestureScale
//                        gestureScale *= delta
//                        print("gestureScale: \(gestureScale)")
//                    }
//                    .onEnded { _ in
//                        currentScale = max(minZoom, min(maxZoom, gestureScale * currentScale))
//                        gestureScale = 1.0
//                        print("currentScale: \(currentScale)")
//                    }
                    .onChanged { val in
                        let delta = val / gestureScale
                        gestureScale *= delta
                        print("gestureScale: \(gestureScale)")
                    }
                    .onEnded { _ in
                        currentScale = max(minZoom, min(maxZoom, gestureScale * currentScale))
                        gestureScale = 1.0
                        print("currentScale: \(currentScale)")
                    }
            )
    }

    init(_ gestureScale: Binding<CGFloat>, _ currentScale: Binding<CGFloat>, minZoom: Double, maxZoom: Double) {
        _gestureScale = Binding(projectedValue: gestureScale)
        _currentScale = Binding(projectedValue: currentScale)
        self.minZoom = minZoom
        self.maxZoom = maxZoom
    }
}
