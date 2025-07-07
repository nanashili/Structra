//
//  ProviderSelectionStepView.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import SwiftUI

struct ProviderSelectionStepView: View {
    let onSelect: (ClientTarget.AIProvider) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("Select a Provider")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 12)
                .padding(.top, 50)
                .multilineTextAlignment(.center)

            Text("Choose which third-party AI provider you want to connect to.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.secondary)
                .padding(.horizontal, 30)

            Spacer()

            VStack(spacing: 15) {
                ForEach(ClientTarget.AIProvider.sortedForDisplay, id: \.self) {
                    provider in
                    Button {
                        onSelect(provider)
                    } label: {
                        HStack(spacing: 12) {
                            Image(provider.logoName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)

                            Text(provider.providerName)
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.white, in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 30)

            Spacer()
        }
    }
}

// MARK: - Preview
struct ProviderSelectionStepView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ProviderSelectionStepView(onSelect: { provider in
                print("Selected provider: \(provider.rawValue)")
            })
        }
        .frame(width: 450, height: 650)
        .previewLayout(.sizeThatFits)
    }
}
