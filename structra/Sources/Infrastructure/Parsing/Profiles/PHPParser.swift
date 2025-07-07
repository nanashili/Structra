//
//  PHPParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct PHPParser: LanguageProfile {
    private static let importKeywords = [
        [UInt8]("include ".utf8), [UInt8]("require ".utf8),
        [UInt8]("use ".utf8),
    ]
    private static let symbolKeywords = [
        [UInt8]("class ".utf8), [UInt8]("function ".utf8),
        [UInt8]("interface ".utf8), [UInt8]("trait ".utf8),
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
