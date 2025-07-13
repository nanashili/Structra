//
//  DocumentationSignature.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 7/10/25.
//

struct DocumentationSignature {
    let name: String
    let parameters: [DocParameter]
    let returnType: String?
    let description: String?

    struct DocParameter {
        let name: String?
        let type: String?
        let description: String?
        let isOptional: Bool
    }
}
