//
//  InternalLoginStepView.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import SwiftUI

struct InternalLoginStepView: View {
    let onSignIn: () -> Void
    let onCreateAccount: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("Structra Cloud")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 12)
                .padding(.top, 50)
                .multilineTextAlignment(.center)

            Text(
                "Sign in to sync your projects, models, and settings across devices."
            )
            .font(.callout)
            .multilineTextAlignment(.center)
            .foregroundStyle(.white.secondary)
            .padding(.horizontal, 30)

            Spacer()

            Button(action: onSignIn) {
                Text("Sign In")
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white, in: .capsule)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 30)

            Button(action: onCreateAccount) {
                Text("Create Account")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Previews
struct InternalLoginStepView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            InternalLoginStepView(
                onSignIn: { print("Sign In tapped") },
                onCreateAccount: { print("Create Account tapped") }
            )
        }
        .frame(width: 450, height: 650)
        .previewLayout(.sizeThatFits)
    }
}
