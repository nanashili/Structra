//
//  ClientTarget.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import Foundation
import SwiftUI

/// Defines the target AI service for a given job.
public enum ClientTarget: Codable, Identifiable {
    case `internal`
    case thirdParty(provider: AIProvider)
    case localhost

    public var id: String {
        switch self {
        case .internal:
            return "internal"
        case .thirdParty(let provider):
            return provider.rawValue
        case .localhost:
            return "localhost"
        }
    }

    /// Provides the name of the image asset for the target's logo.
    var logoName: String {
        switch self {
        case .internal:
            return "structra_logo"
        case .thirdParty(let provider):
            return provider.logoName
        case .localhost:
            return "localhost_icon"
        }
    }

    public enum AIProvider: String, Codable, CaseIterable {
        case openAI
        case claude
        case mistral
        case gemini
        case llama

        var providerName: String {
            switch self {
            case .openAI:
                return "OpenAI"
            case .claude:
                return "Claude"
            case .mistral:
                return "Mistral"
            case .gemini:
                return "Gemini"
            case .llama:
                return "Llama"
            }
        }

        /// Provides the name of the image asset for the provider's logo.
        var logoName: String {
            switch self {
            case .openAI:
                return "OpenAI"
            case .claude:
                return "Claude"
            case .mistral:
                return "AI"
            case .gemini:
                return "Gemini"
            case .llama:
                return "AI"
            }
        }

        /// Returns the providers sorted with generic ones at the bottom.
        static var sortedForDisplay: [AIProvider] {
            allCases.sorted { provider1, provider2 in
                let sortOrder1 = (provider1.logoName == "AI") ? 1 : 0
                let sortOrder2 = (provider2.logoName == "AI") ? 1 : 0

                return sortOrder1 < sortOrder2
            }
        }
    }
}
