//
//  CodeSignature.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 7/10/25.
//

struct CodeSignature {
    let name: String
    let parameters: [Parameter]
    let returnType: String?
    let language: String
    let rawSignature: String

    struct Parameter {
        let name: String?
        let type: String?
        let defaultValue: String?
        let isOptional: Bool
    }
}
