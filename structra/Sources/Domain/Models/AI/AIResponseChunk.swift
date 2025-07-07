//
//  AIResponseChunk.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import Foundation

/// Represents a chunk of a streaming response from an AI service.
public struct AIResponseChunk {
    public let id: String
    public let content: String
    public let isFinal: Bool
}
