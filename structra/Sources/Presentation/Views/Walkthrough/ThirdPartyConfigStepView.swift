//
//  ThirdPartyConfigStepView.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import SwiftUI

struct ThirdPartyConfigStepView: View {
    let providerName: String
    @Binding var url: String
    @Binding var apiKey: String
    @Binding var header: String
    @Binding var description: String
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("Configure \(providerName)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 12)
                .padding(.top, 50)
                .multilineTextAlignment(.center)

            Text(
                "Provide the connection details for your third-party provider."
            )
            .font(.callout)
            .multilineTextAlignment(.center)
            .foregroundStyle(.white.secondary)
            .padding(.horizontal, 30)
            .padding(.bottom, 20)

            Spacer()

            VStack(spacing: 15) {
                TextField("URL", text: $url)
                    .padding()
                    .background(
                        .white.opacity(0.1),
                        in: .rect(cornerRadius: 12)
                    )
                    .foregroundStyle(.white)
                    .textContentType(.URL)

                SecureField("API Key", text: $apiKey)
                    .padding()
                    .background(
                        .white.opacity(0.1),
                        in: .rect(cornerRadius: 12)
                    )
                    .foregroundStyle(.white)

                TextField("API Key Header (e.g., Authorization)", text: $header)
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

            // This spacer pushes the button to the bottom.
            Spacer()

            // Primary Action Button
            Button(action: onContinue) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white, in: .capsule)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Previews
struct ThirdPartyConfigStepView_Previews: PreviewProvider {
    @State static var url: String = "https://api.openai.com/v1"
    @State static var apiKey: String = ""
    @State static var header: String = "Authorization"
    @State static var description: String = "My OpenAI Key"

    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ThirdPartyConfigStepView(
                providerName: "OpenAI",
                url: $url,
                apiKey: $apiKey,
                header: $header,
                description: $description,
                onContinue: {
                    print("Continue tapped for third-party config")
                }
            )
        }
        .frame(width: 450, height: 650)
        .previewLayout(.sizeThatFits)
    }
}
