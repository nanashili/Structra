//
//  ElixirParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct ElixirParser: LanguageProfile {
    private static let importKeywords = [
        [UInt8]("import ".utf8), [UInt8]("require ".utf8), [UInt8]("use ".utf8),
        [UInt8]("alias ".utf8),
    ]
    private static let symbolKeywords: [[UInt8]] = [
        [UInt8]("defmodule ".utf8), [UInt8]("def ".utf8), [UInt8]("defp ".utf8),
        [UInt8]("defmacro ".utf8), [UInt8]("defmacrop ".utf8),
        [UInt8]("defguard ".utf8),
        [UInt8]("defprotocol ".utf8), [UInt8]("defimpl ".utf8),
        [UInt8]("defexception ".utf8),
        [UInt8]("defstruct ".utf8),
    ].map { $0 }
    var pattern: LanguagePattern {
        LanguagePattern(
            language: "Elixir",
            functionPattern: #"def(?:p)?\s+([^\(]+)\(([^)]*)\)"#,
            parameterPattern: #"(\w+)"#,
            returnTypePattern: ""
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
