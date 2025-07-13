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
/// Defines the capabilities for parsing a specific language, including symbol extraction and signature patterns.
public protocol LanguageProfile {
    /// Extracts import statements from the given code data.
    func extractImports(from data: Data) -> [String]

    /// Extracts symbol definitions (classes, functions, etc.) from the given code data.
    func extractSymbols(from data: Data) -> [String]

    /// Provides the regex patterns for parsing function signatures.
    var pattern: LanguagePattern { get }
}
