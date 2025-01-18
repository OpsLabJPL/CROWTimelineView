//
//  NowLine.swift
//  CROW-iOS
//
//  Created by Mark Powell on 7/27/23.
//

import SwiftUI

struct NowLine: View {
    @Bindable var viewModel: TimelineViewModel
    @Binding var simNow: Date

    var body: some View {
        Canvas { context, size in
            let originX = (
                simNow.timeIntervalSinceReferenceDate -
                viewModel.earliestTime.timeIntervalSinceReferenceDate
            )
            let xform = CGAffineTransform(translationX: viewModel.scrollOffset.x, y: 0.0)
                .scaledBy(x: viewModel.viewXform.convertDurationToWidth, y: 1.0)
            let origin = CGPoint(x: originX, y: 0)
            let viewLineOrigin = origin.applying(xform)
            var path = Path()
            path.move(to: viewLineOrigin)
            path.addLine(to: CGPoint(x: viewLineOrigin.x, y: size.height))
            context.stroke(path, with: .color(Color.red), style: .init(lineWidth: 2))
        }
    }
}
