//
//  RustParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct RustParser: LanguageProfile {
    private static let importKeywords = [
        [UInt8]("use ".utf8), [UInt8]("mod ".utf8),
    ]
    private static let symbolKeywords = [
        [UInt8]("fn ".utf8), [UInt8]("struct ".utf8), [UInt8]("enum ".utf8),
        [UInt8]("mod ".utf8), [UInt8]("trait ".utf8), [UInt8]("impl ".utf8),
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
