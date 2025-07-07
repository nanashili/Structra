//
//  DartParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct DartParser: LanguageProfile {
    private static let importKeywords = [
        [UInt8]("import ".utf8), [UInt8]("part ".utf8),
    ]
    private static let symbolKeywords = [
        [UInt8]("class ".utf8), [UInt8]("enum ".utf8), [UInt8]("mixin ".utf8),
        [UInt8]("void ".utf8),
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
