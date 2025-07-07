//
//  PromptJob.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import Foundation

/// Represents a single unit of work for the AI Client.
public struct PromptJob {
    /// The destination for the request.
    public let target: ClientTarget

    /// The data payload containing context, content, and metadata.
    public let inputData: [String: Any]

    /// The key (e.g., filename) for the prompt template.
    /// Required for `.thirdParty` and `.localhost` targets.
    public let promptTemplateKey: String?

    public init(
        target: ClientTarget,
        inputData: [String: Any],
        promptTemplateKey: String? = nil
    ) {
        self.target = target
        self.inputData = inputData
        self.promptTemplateKey = promptTemplateKey
    }
}
