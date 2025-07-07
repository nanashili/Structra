//
//  TargetSelectionStepView.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import SwiftUI

struct TargetSelectionStepView: View {
    let onSelect: (ClientTarget) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("How will you connect?")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 12)
                .padding(.top, 50)
                .multilineTextAlignment(.center)

            Text(
                "You can change this later in settings to use a different configuration if you like."
            )
            .font(.callout)
            .multilineTextAlignment(.center)
            .foregroundStyle(.white.secondary)
            .padding(.horizontal, 30)

            Spacer()

            Button {
                onSelect(.internal)
            } label: {
                Text("Structra Cloud (Coming Soon")
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(.white, in: .capsule)
            }
            .buttonStyle(.plain)
            .disabled(true)

            Button {
                onSelect(.thirdParty(provider: .openAI))
            } label: {
                Text("Third-Party Provider")
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(.white, in: .capsule)
            }
            .buttonStyle(.plain)
            
            Spacer()

            Button {
                onSelect(.localhost)
            } label: {
                Text("Localhost")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
        }
    }
}

struct TargetSelectionStepView_Previews: PreviewProvider {
    static var previews: some View {
        TargetSelectionStepView(onSelect: { target in
            print("Selected target: \(target)")
        })
        .padding()
        .frame(width: 450, height: 650)
        .previewLayout(.sizeThatFits)
    }
}
