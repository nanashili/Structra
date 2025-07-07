//
//  NoOpParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct NoOpParser: LanguageProfile {
    func extractImports(from data: Data) -> [String] { [] }
    func extractSymbols(from data: Data) -> [String] { [] }
}
