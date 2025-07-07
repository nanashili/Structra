//
//  WelcomeStepView.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import Combine
import SwiftUI

struct WelcomeStepView: View {
    let onNext: () -> Void

    @State private var points: [SIMD2<Float>] = []

    // The original colors from your design
    private let initialColors: [Color] = [
        Color(red: 0.36, green: 0.13, blue: 0.98),  // Electric Purple
        Color(red: 0.00, green: 0.98, blue: 1.00),  // Neon Cyan
        Color(red: 0.00, green: 0.80, blue: 0.60),  // Aqua Green
        Color(red: 0.29, green: 0.00, blue: 0.51),  // Deep Indigo
        Color(red: 0.60, green: 0.00, blue: 1.00),  // Vivid Violet
        Color(red: 0.00, green: 0.60, blue: 1.00),  // AI Blue
        Color(red: 0.00, green: 0.98, blue: 1.00),  // Neon Cyan
        Color(red: 0.00, green: 0.80, blue: 0.60),  // Aqua Green
        Color(red: 0.36, green: 0.13, blue: 0.98),  // Electric Purple
    ]

    var body: some View {
        // The main content VStack is now the top-level view
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Text("Welcome to")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))

                Text("Structra")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.bottom, 12)

                Text(
                    "Automatically generate and maintain documentation for your codebases and APIs. To begin, let's configure how Structra connects to its AI services."
                )
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.secondary)
            }
            .padding(.horizontal, 40)

            Spacer()

            Button(action: onNext) {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(.white, in: .capsule)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .background(
            MeshGradient(
                width: 3,
                height: 3,
                points: points,
                colors: initialColors
            )
            .blur(radius: 80)
            .ignoresSafeArea()
            .onAppear(perform: startAnimation)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Animation Logic

    private let basePoints: [SIMD2<Float>] = [
        [0, 0], [0.5, 0], [1, 0],
        [0, 0.5], [0.5, 0.5], [1, 0.5],
        [0, 1], [0.5, 1], [1, 1],
    ]

    private func startAnimation() {
        self.points = basePoints

        animateGradient()
    }

    private func animateGradient() {
        let newPoints = basePoints.map { point in
            let randomOffset = SIMD2<Float>(
                .random(in: -0.4...0.4),
                .random(in: -0.4...0.4)
            )
            return SIMD2<Float>(
                x: (point.x + randomOffset.x).clamped(to: 0...1),
                y: (point.y + randomOffset.y).clamped(to: 0...1)
            )
        }

        withAnimation(.timingCurve(0.5, 0, 0.5, 1, duration: 6)) {
            self.points = newPoints
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            animateGradient()
        }
    }
}

// MARK: - Preview
struct WelcomeStepView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeStepView(onNext: {})
            .frame(width: 450, height: 650)
    }
}
