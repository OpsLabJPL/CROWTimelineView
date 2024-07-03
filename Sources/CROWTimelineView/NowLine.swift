//
//  NowLine.swift
//  CROW-iOS
//
//  Created by Mark Powell on 7/27/23.
//

import SwiftUI

struct NowLine: View {
    @ObservedObject var viewModel: TimelineViewModel
    @Binding var scrollOffset: CGPoint
    @Binding var simNow: Date

    var body: some View {
        Canvas { context, size in
            let originX = (
                simNow.timeIntervalSinceReferenceDate -
                viewModel.earliestTime.timeIntervalSinceReferenceDate
            )
            let xform = CGAffineTransform(translationX: scrollOffset.x, y: 0.0)
                .scaledBy(x: viewModel.convertDurationToWidth, y: 1.0)
            let origin = CGPoint(x: originX, y: 0)
            let viewLineOrigin = origin.applying(xform)
            var path = Path()
            path.move(to: viewLineOrigin)
            path.addLine(to: CGPoint(x: viewLineOrigin.x, y: size.height))
            context.stroke(path, with: .color(Color.red), style: .init(lineWidth: 2))
        }
    }
}
