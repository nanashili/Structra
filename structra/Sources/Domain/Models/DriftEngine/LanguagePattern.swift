//
//  LanguagePattern.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 7/10/25.
//

/// A structure to hold the regex patterns for parsing a language.
public struct LanguagePattern {
    let language: String
    let functionPattern: String
    let parameterPattern: String
    let returnTypePattern: String
}
