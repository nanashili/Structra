//
//  CStyleParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct CStyleParser: LanguageProfile {
    private static let importKeywords = [
        [UInt8]("#import ".utf8), [UInt8]("#include ".utf8),
    ]
    private static let symbolKeywords = [
        [UInt8]("@interface ".utf8), [UInt8]("@implementation ".utf8),
        [UInt8]("class ".utf8), [UInt8]("struct ".utf8), [UInt8]("enum ".utf8),
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
