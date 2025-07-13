//
//  NoOpParser.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 7/10/25.
//

import Foundation

struct NoOpParser: LanguageProfile {
    var pattern: LanguagePattern {
        LanguagePattern(
            language: "noop",
            functionPattern: "",
            parameterPattern: "",
            returnTypePattern: ""
        )
    }
    func extractImports(from data: Data) -> [String] { [] }
    func extractSymbols(from data: Data) -> [String] { [] }
}
