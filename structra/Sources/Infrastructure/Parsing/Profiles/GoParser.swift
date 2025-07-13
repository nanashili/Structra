//
//  GoParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct GoParser: LanguageProfile {
    private static let importKeywords = [[UInt8]("import ".utf8)]
    private static let symbolKeywords: [[UInt8]] = [
        [UInt8]("func ".utf8), [UInt8]("type ".utf8), [UInt8]("const ".utf8),
        [UInt8]("var ".utf8), [UInt8]("interface ".utf8),
    ].map { $0 }
    var pattern: LanguagePattern {
        LanguagePattern(
            language: "Go",
            functionPattern:
                #"func\s+(?:\([^)]*\)\s+)?(\w+)\s*\(([^)]*)\)\s*([^{]*)?"#,
            parameterPattern: #"(\w+)\s+([\w\.\*\[\]]+)"#,
            returnTypePattern: #"\)\s*([^{]+)"#
        )
    }
    func extractImports(from data: Data) -> [String] {
        ByteParserUtils.extractImports(
            from: data,
            keywords: Self.importKeywords
        )
    }
    func extractSymbols(from data: Data) -> [String] {
        ByteParserUtils.extractSymbols(
            from: data,
            keywords: Self.symbolKeywords
        )
    }
}
