//
//  AIError.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import Foundation

/// Defines custom errors related to AI operations within the WorkspaceManager.
public enum AIError: Error, LocalizedError {
    /// An error indicating that the operation was attempted on a folder, which is not supported.
    case folderNotSupported
    /// An error indicating that the content of the target file could not be read.
    case fileReadError(Error)

    public var errorDescription: String? {
        switch self {
        case .folderNotSupported:
            return
                "AI generation is currently only supported for individual files, not for entire folders."
        case .fileReadError(let underlyingError):
            return
                "Failed to read file content: \(underlyingError.localizedDescription)"
        }
    }
}
