//
//  JavaFamilyParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct JavaFamilyParser: LanguageProfile {
    private static let importKeywords = [
        [UInt8]("import ".utf8), [UInt8]("using ".utf8),
    ]
    private static let symbolKeywords = [
        [UInt8]("class ".utf8), [UInt8]("interface ".utf8),
        [UInt8]("enum ".utf8), [UInt8]("record ".utf8),
    ]
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
