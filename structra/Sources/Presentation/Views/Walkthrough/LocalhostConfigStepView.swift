//
//  LocalhostConfigStepView.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import SwiftUI

struct LocalhostConfigStepView: View {
    @Binding var port: String
    @Binding var description: String

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("Localhost Setup")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 50)
                .multilineTextAlignment(.center)

            Spacer()

            Text(
                "Enter the port and an optional description for your local connection."
            )
            .font(.callout)
            .multilineTextAlignment(.center)
            .foregroundStyle(.white.secondary)
            .padding(.horizontal, 30)
            .padding(.bottom, 20)

            VStack(spacing: 15) {
                TextField("Port (e.g., 11434)", text: $port)
                    .padding()
                    .background(
                        .white.opacity(0.1),
                        in: .rect(cornerRadius: 12)
                    )
                    .foregroundStyle(.white)

                TextField("Description (Optional)", text: $description)
                    .padding()
                    .background(
                        .white.opacity(0.1),
                        in: .rect(cornerRadius: 12)
                    )
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 30)

            Spacer()
        }
    }
}

// MARK: - Previews
struct LocalhostConfigStepView_Previews: PreviewProvider {
    // Use @State to provide mutable bindings for the preview
    @State static var port: String = "11434"
    @State static var description: String = "Ollama"

    static var previews: some View {
        // Use a ZStack to provide a dark background for the preview
        ZStack {
            Color.black.ignoresSafeArea()
            LocalhostConfigStepView(
                port: $port,
                description: $description
            )
        }
        .frame(width: 450, height: 650)
        .previewLayout(.sizeThatFits)
    }
}
