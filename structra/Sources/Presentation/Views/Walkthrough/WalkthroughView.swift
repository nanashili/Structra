//
//  WalkthroughView.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import SwiftUI

struct WalkthroughView: View {
    /// An enum to represent the steps in our setup wizard.
    private enum Step {
        case welcome
        case targetSelection
        case providerSelection
        case localhostConfig
        case thirdPartyConfig
        case internalLogin
    }

    @Binding var hasCompletedWalkthrough: Bool

    // State for the current step and data
    @State private var currentStep: Step = .welcome
    @State private var clientTarget: ClientTarget = .internal

    // Configuration state
    @State private var localhostPort: String = "8080"
    @State private var thirdPartyURL: String = ""
    @State private var thirdPartyApiKey: String = ""
    @State private var thirdPartyHeader: String = "X-API-Key"
    @State private var description: String = ""

    var body: some View {
        VStack {
            switch currentStep {
            case .welcome:
                WelcomeStepView(onNext: {
                    currentStep = .targetSelection
                })

            case .targetSelection:
                TargetSelectionStepView(onSelect: { target in
                    self.clientTarget = target
                    switch target {
                    case .localhost: currentStep = .localhostConfig
                    case .thirdParty: currentStep = .providerSelection
                    case .internal: currentStep = .internalLogin
                    }
                })

            case .providerSelection:
                ProviderSelectionStepView(onSelect: { provider in
                    self.clientTarget = .thirdParty(provider: provider)
                    currentStep = .thirdPartyConfig
                })

            case .localhostConfig:
                LocalhostConfigStepView(
                    port: $localhostPort,
                    description: $description
                )

            case .thirdPartyConfig:
                if case .thirdParty(let provider) = clientTarget {
                    ThirdPartyConfigStepView(
                        providerName: provider.providerName,
                        url: $thirdPartyURL,
                        apiKey: $thirdPartyApiKey,
                        header: $thirdPartyHeader,
                        description: $description,
                        onContinue: {
                            saveSettingsAndFinish()
                        }
                    )
                }

            case .internalLogin:
                InternalLoginStepView(
                    onSignIn: { print("Sign In tapped") },
                    onCreateAccount: { print("Create Account tapped") }
                )
            }
        }
        .frame(width: 450, height: 650)
        .background(
            Material.bar,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .background(
            WindowAccessor { window in
                window.styleMask.remove(.titled)
                window.isMovableByWindowBackground = true
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.center()

                window.isOpaque = false
                window.backgroundColor = .clear

                window.contentView?.wantsLayer = true
                window.contentView?.layer?.cornerRadius = 12
                window.contentView?.layer?.masksToBounds = true
            }
        )
    }

    private func saveSettingsAndFinish() {
        var config: [String: String] = ["description": description]

        switch clientTarget {
        case .localhost:
            config["port"] = localhostPort
            AppSettings.saveConfiguration(
                target: clientTarget,
                configuration: config
            )

        case .thirdParty(let provider):
            config["provider"] = provider.rawValue
            config["url"] = thirdPartyURL
            config["header"] = thirdPartyHeader

            AppSettings.saveThirdPartyConfiguration(
                target: clientTarget,
                apiKey: thirdPartyApiKey,
                configuration: config
            )

        case .internal:
            AppSettings.saveConfiguration(
                target: clientTarget,
                configuration: [:]
            )
        }

        AppSettings.hasCompletedWalkthrough = true
        self.hasCompletedWalkthrough = true
    }
}
