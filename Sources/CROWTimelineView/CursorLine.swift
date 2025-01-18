//
//  CursorLine.swift
//  CROW-iOS
//
//  Created by Mark Powell on 8/29/23.
//

import SwiftUI

struct CursorLine: View {
    @Bindable var viewModel: TimelineViewModel
    @Binding var selectedTime: Date?

    var body: some View {
        Canvas { context, size in
            if let selectedTime {
                let originX = (
                    selectedTime.timeIntervalSinceReferenceDate -
                    viewModel.earliestTime.timeIntervalSinceReferenceDate
                )
                let xform = CGAffineTransform(translationX: viewModel.scrollOffset.x, y: 0.0)
                    .scaledBy(x: viewModel.viewXform.convertDurationToWidth, y: 1.0)
                let origin = CGPoint(x: originX, y: 0)
                let viewLineOrigin = origin.applying(xform)
                var path = Path()
                path.move(to: viewLineOrigin)
                path.addLine(to: CGPoint(x: viewLineOrigin.x, y: size.height))
                context.stroke(path, with: .color(Color.blue), style: .init(lineWidth: 3))
            }
        }
    }
}
