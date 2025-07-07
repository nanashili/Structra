//
//  ElixirParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct ElixirParser: LanguageProfile {
    private static let importKeywords = [
        [UInt8]("alias ".utf8), [UInt8]("import ".utf8),
        [UInt8]("require ".utf8), [UInt8]("use ".utf8),
    ]
    private static let symbolKeywords = [
        [UInt8]("defmodule ".utf8), [UInt8]("def ".utf8), [UInt8]("defp ".utf8),
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
