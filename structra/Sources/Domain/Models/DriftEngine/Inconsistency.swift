//
//  Inconsistency.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 7/10/25.
//

struct Inconsistency {
    enum InconsistencyType {
        case missingInDocumentation
        case missingInCode
        case parameterCountMismatch
        case parameterTypeMismatch
        case parameterNameMismatch
        case returnTypeMismatch
        case parameterOrderMismatch
    }

    let type: InconsistencyType
    let codeSignature: CodeSignature?
    let docSignature: DocumentationSignature?
    let details: String
}
