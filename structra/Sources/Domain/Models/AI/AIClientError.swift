//
//  AIClientError.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import Foundation

/// Defines custom errors for the AI Client for better diagnostics.
public enum AIClientError: Error, LocalizedError {
    case missingConfiguration(String)
    case templateNotFound(String)
    case missingTemplateKey
    case placeholderMissingInTemplate(key: String, template: String)
    case networkError(underlyingError: Error)
    case invalidResponseData
    case requestBuildingFailed(String)
    case fileReadError(ProjectNode)

    public var errorDescription: String? {
        switch self {
        case .missingConfiguration(let detail):
            return "Configuration Error: \(detail)"
        case .templateNotFound(let key):
            return "Prompt template '\(key)' not found."
        case .missingTemplateKey:
            return "A promptTemplateKey is required for this target."
        case .placeholderMissingInTemplate(let key, let template):
            return
                "The placeholder '{{\(key)}}' was not found in the template: \(template.prefix(100))..."
        case .networkError(let underlyingError):
            return
                "Network request failed: \(underlyingError.localizedDescription)"
        case .invalidResponseData:
            return "Received invalid or non-decodable data from the server."
        case .requestBuildingFailed(let reason):
            return "Failed to build the API request: \(reason)"
        case .fileReadError(let node):
            return "Could not read content of \(node.name)"
        }
    }
}
