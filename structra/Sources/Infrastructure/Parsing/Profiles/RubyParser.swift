//
//  RubyParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct RubyParser: LanguageProfile {
    private static let importKeywords = [
        [UInt8]("require ".utf8), [UInt8]("load ".utf8),
    ]
    private static let symbolKeywords = [
        [UInt8]("class ".utf8), [UInt8]("module ".utf8), [UInt8]("def ".utf8),
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
