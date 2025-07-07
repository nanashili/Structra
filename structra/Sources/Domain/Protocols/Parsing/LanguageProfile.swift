//
//  LanguageProfile.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

// LanguageProfile.swift

import Foundation

/// Defines the contract for a HYPER-OPTIMIZED language-specific parser.
/// It operates directly on raw `Data` for maximum performance.
public protocol LanguageProfile {
    /// Extracts import/require/include statements from the file's raw data.
    func extractImports(from data: Data) -> [String]

    /// Extracts high-level symbol declarations from the file's raw data.
    func extractSymbols(from data: Data) -> [String]
}
