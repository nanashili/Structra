//
//  ProgressRingView.swift
//  structra
//
//  Created by Nanashi Li on 7/4/25.
//

import SwiftUI

/// A clean, indeterminate progress ring view similar to those found in iOS.
/// It displays a spinning arc, providing a visually pleasing loading indicator.
struct ProgressRingView: View {
    /// The color of the spinning ring.
    var color: Color = .accentColor

    /// The thickness of the ring.
    var lineWidth: CGFloat = 3.0

    // Internal state to drive the continuous rotation animation.
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // 1. The background track of the ring (the faint circle)
            Circle()
                .stroke(color.opacity(0.3), lineWidth: lineWidth)

            // 2. The spinning arc that indicates progress
            Circle()
                // Trim the circle to be a small arc (e.g., a quarter circle)
                .trim(from: 0, to: 0.25)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                // Rotate the arc. The animation will spin it from 0 to 360 degrees.
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
        }
        .onAppear {
            // Start the animation when the view appears.
            // It's a linear, forever-repeating animation.
            withAnimation(
                .linear(duration: 1).repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview
struct ProgressRingView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressRingView()
            .frame(width: 50, height: 50)
            .padding()
    }
}
