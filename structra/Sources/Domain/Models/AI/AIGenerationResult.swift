//
//  AIGenerationResult.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import Foundation

/// Represents the output from an AI generation task.
///
/// This enum allows a single publisher to communicate different states of the generation
/// process: new content chunks, successful completion, or failure with an error.
public enum AIGenerationResult {
    /// A new chunk of text has been generated and is available.
    case chunk(String)
    /// The generation task completed successfully.
    case success
    /// The generation task failed with an error.
    case failure(Error)
}
