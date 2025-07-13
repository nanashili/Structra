//
//  SignatureConsistencyChecker.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 7/10/25.
//

import Foundation

class SignatureConsistencyChecker {

    // MARK: - Public Interface

    /// Checks the consistency between code and its documentation for a given language.
    /// - Parameters:
    ///   - code: A string containing the source code.
    ///   - documentation: A string containing the documentation.
    ///   - language: The `Language` enum value for the source code.
    /// - Returns: An array of `Inconsistency` objects detailing any mismatches found.
    func checkConsistency(
        code: String,
        documentation: String,
        language: Language
    ) -> [Inconsistency] {
        // 1. Get the language profile from the registry.
        let languageProfile = LanguageRegistry.profile(for: language)

        // 2. Use the pattern from the profile to parse signatures.
        let codeSignatures = parseCodeSignatures(
            from: code,
            using: languageProfile.pattern
        )
        let docSignatures = parseDocumentationSignatures(from: documentation)

        return findInconsistencies(between: codeSignatures, and: docSignatures)
    }

    // MARK: - Code Parsing

    /// Parses code signatures from a string using the provided language pattern.
    private func parseCodeSignatures(
        from code: String,
        using pattern: LanguagePattern
    ) -> [CodeSignature] {
        var signatures: [CodeSignature] = []
        guard !pattern.functionPattern.isEmpty else { return signatures }

        do {
            let regex = try NSRegularExpression(
                pattern: pattern.functionPattern,
                options: []
            )
            let matches = regex.matches(
                in: code,
                options: [],
                range: NSRange(location: 0, length: code.utf16.count)
            )

            for match in matches {
                if let signature = extractSignature(
                    from: code,
                    match: match,
                    pattern: pattern,
                    language: pattern.language
                ) {
                    signatures.append(signature)
                }
            }
        } catch {
            print("Regex error while parsing code signatures: \(error)")
        }

        return signatures
    }

    private func extractSignature(
        from code: String,
        match: NSTextCheckingResult,
        pattern: LanguagePattern,
        language: String
    ) -> CodeSignature? {
        let nsString = code as NSString

        // Extract function name
        guard match.numberOfRanges > 1,
            let nameRange = Range(match.range(at: 1), in: code)
        else { return nil }
        let name = String(code[nameRange])

        // Extract parameters
        var parameters: [CodeSignature.Parameter] = []
        if match.numberOfRanges > 2 {
            if let paramRange = Range(match.range(at: 2), in: code) {
                let paramString = String(code[paramRange])
                parameters = parseParameters(paramString, pattern: pattern)
            }
        }

        // Extract return type
        var returnType: String?
        if match.numberOfRanges > 3 {
            if let returnRange = Range(match.range(at: 3), in: code) {
                returnType = String(code[returnRange])
            }
        }

        // Get raw signature
        let rawSignature = nsString.substring(with: match.range)

        return CodeSignature(
            name: name,
            parameters: parameters,
            returnType: returnType,
            language: language,
            rawSignature: rawSignature
        )
    }

    private func parseParameters(
        _ paramString: String,
        pattern: LanguagePattern
    ) -> [CodeSignature.Parameter] {
        var parameters: [CodeSignature.Parameter] = []
        let paramComponents = paramString.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }

        for component in paramComponents {
            if component.isEmpty { continue }

            do {
                let regex = try NSRegularExpression(
                    pattern: pattern.parameterPattern,
                    options: []
                )
                let match = regex.firstMatch(
                    in: component,
                    options: [],
                    range: NSRange(location: 0, length: component.utf16.count)
                )

                if let match = match {
                    var name: String?
                    var type: String?
                    var defaultValue: String?

                    // Extract based on number of capture groups
                    if match.numberOfRanges > 1,
                        let range = Range(match.range(at: 1), in: component)
                    {
                        name = String(component[range])
                    }
                    if match.numberOfRanges > 2,
                        let range = Range(match.range(at: 2), in: component)
                    {
                        type = String(component[range])
                    }
                    if match.numberOfRanges > 3,
                        let range = Range(match.range(at: 3), in: component)
                    {
                        defaultValue = String(component[range])
                    }

                    // Handle different language conventions
                    if pattern.language == "java" && type != nil && name == nil
                    {
                        // In Java pattern, first capture is type, second is name
                        name = type
                        type =
                            match.numberOfRanges > 1
                            ? String(
                                component[
                                    Range(match.range(at: 1), in: component)!
                                ]
                            ) : nil
                    }

                    let isOptional =
                        component.contains("?") || defaultValue != nil

                    parameters.append(
                        CodeSignature.Parameter(
                            name: name ?? component,
                            type: type,
                            defaultValue: defaultValue,
                            isOptional: isOptional
                        )
                    )
                }
            } catch {
                // Fallback: treat entire component as parameter name
                parameters.append(
                    CodeSignature.Parameter(
                        name: component,
                        type: nil,
                        defaultValue: nil,
                        isOptional: false
                    )
                )
            }
        }

        return parameters
    }

    // MARK: - Documentation Parsing

    private func parseDocumentationSignatures(from documentation: String)
        -> [DocumentationSignature]
    {
        var signatures: [DocumentationSignature] = []

        // Common documentation patterns
        let patterns = [
            // JSDoc style
            #"@(?:function|method)\s+(\w+)\s*\((.*?)\)(?:\s*:\s*(\w+))?"#,
            // Python docstring style
            #"(\w+)\((.*?)\)(?:\s*->\s*(\w+))?"#,
            // Markdown style
            #"###?\s+`?(\w+)\((.*?)\)`?(?:\s*->\s*`?(\w+)`?)?"#,
            // Generic function documentation
            #"Function:\s*(\w+)\s*\((.*?)\)"#,
        ]

        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(
                    pattern: pattern,
                    options: [.caseInsensitive]
                )
                let matches = regex.matches(
                    in: documentation,
                    options: [],
                    range: NSRange(
                        location: 0,
                        length: documentation.utf16.count
                    )
                )

                for match in matches {
                    if let signature = extractDocSignature(
                        from: documentation,
                        match: match
                    ) {
                        signatures.append(signature)
                    }
                }
            } catch {
                continue
            }
        }

        // Also parse parameter documentation
        signatures = enrichWithParameterDocs(
            signatures,
            documentation: documentation
        )

        return signatures
    }

    private func extractDocSignature(
        from documentation: String,
        match: NSTextCheckingResult
    ) -> DocumentationSignature? {
        guard match.numberOfRanges > 1,
            let nameRange = Range(match.range(at: 1), in: documentation)
        else { return nil }

        let name = String(documentation[nameRange])

        var parameters: [DocumentationSignature.DocParameter] = []
        if match.numberOfRanges > 2,
            let paramRange = Range(match.range(at: 2), in: documentation)
        {
            let paramString = String(documentation[paramRange])
            parameters = parseDocParameters(paramString)
        }

        var returnType: String?
        if match.numberOfRanges > 3,
            let returnRange = Range(match.range(at: 3), in: documentation)
        {
            returnType = String(documentation[returnRange])
        }

        return DocumentationSignature(
            name: name,
            parameters: parameters,
            returnType: returnType,
            description: nil
        )
    }

    private func parseDocParameters(_ paramString: String)
        -> [DocumentationSignature.DocParameter]
    {
        var parameters: [DocumentationSignature.DocParameter] = []
        let components = paramString.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }

        for component in components {
            if component.isEmpty { continue }

            // Try to extract type and name
            let typePattern = #"(\w+):\s*(\w+)"#
            let simplePattern = #"(\w+)"#

            var name: String?
            var type: String?

            if let match = component.range(
                of: typePattern,
                options: .regularExpression
            ) {
                let parts = component.split(separator: ":")
                if parts.count >= 2 {
                    name = String(parts[0]).trimmingCharacters(in: .whitespaces)
                    type = String(parts[1]).trimmingCharacters(in: .whitespaces)
                }
            } else {
                name = component
            }

            let isOptional =
                component.contains("?")
                || component.lowercased().contains("optional")

            parameters.append(
                DocumentationSignature.DocParameter(
                    name: name,
                    type: type,
                    description: nil,
                    isOptional: isOptional
                )
            )
        }

        return parameters
    }

    private func enrichWithParameterDocs(
        _ signatures: [DocumentationSignature],
        documentation: String
    ) -> [DocumentationSignature] {
        // Look for @param, :param, Parameters: sections
        let paramPatterns = [
            #"@param\s+(?:\{(\w+)\})?\s*(\w+)\s*-?\s*(.+)"#,
            #":param\s+(\w+)\s*(\w+):\s*(.+)"#,
            #"Parameters?:\s*\n((?:\s*-?\s*\w+.*\n?)+)"#,
        ]

        // This is a simplified version - in production, you'd want to associate
        // parameter docs with the correct function
        return signatures
    }

    // MARK: - Inconsistency Detection

    private func findInconsistencies(
        between codeSignatures: [CodeSignature],
        and docSignatures: [DocumentationSignature]
    ) -> [Inconsistency] {
        var inconsistencies: [Inconsistency] = []

        // Check each code signature against documentation
        for codeSignature in codeSignatures {
            if let matchingDoc = docSignatures.first(where: {
                $0.name == codeSignature.name
            }) {
                // Compare signatures
                inconsistencies.append(
                    contentsOf: compareSignatures(
                        code: codeSignature,
                        doc: matchingDoc
                    )
                )
            } else {
                // Function missing in documentation
                inconsistencies.append(
                    Inconsistency(
                        type: .missingInDocumentation,
                        codeSignature: codeSignature,
                        docSignature: nil,
                        details:
                            "Function '\(codeSignature.name)' is not documented"
                    )
                )
            }
        }

        // Check for documented functions missing in code
        for docSignature in docSignatures {
            if !codeSignatures.contains(where: { $0.name == docSignature.name })
            {
                inconsistencies.append(
                    Inconsistency(
                        type: .missingInCode,
                        codeSignature: nil,
                        docSignature: docSignature,
                        details:
                            "Documented function '\(docSignature.name)' not found in code"
                    )
                )
            }
        }

        return inconsistencies
    }

    private func compareSignatures(
        code: CodeSignature,
        doc: DocumentationSignature
    ) -> [Inconsistency] {
        var inconsistencies: [Inconsistency] = []

        // Check parameter count
        if code.parameters.count != doc.parameters.count {
            inconsistencies.append(
                Inconsistency(
                    type: .parameterCountMismatch,
                    codeSignature: code,
                    docSignature: doc,
                    details:
                        "Parameter count mismatch: code has \(code.parameters.count), documentation has \(doc.parameters.count)"
                )
            )
        }

        // Check return type
        if let codeReturn = code.returnType, let docReturn = doc.returnType {
            if !areTypesEquivalent(codeReturn, docReturn) {
                inconsistencies.append(
                    Inconsistency(
                        type: .returnTypeMismatch,
                        codeSignature: code,
                        docSignature: doc,
                        details:
                            "Return type mismatch: code returns '\(codeReturn)', documentation says '\(docReturn)'"
                    )
                )
            }
        }

        // Check individual parameters
        let minParamCount = min(code.parameters.count, doc.parameters.count)
        for i in 0..<minParamCount {
            let codeParam = code.parameters[i]
            let docParam = doc.parameters[i]

            // Check parameter names
            if let codeName = codeParam.name, let docName = docParam.name {
                if codeName != docName {
                    inconsistencies.append(
                        Inconsistency(
                            type: .parameterNameMismatch,
                            codeSignature: code,
                            docSignature: doc,
                            details:
                                "Parameter name mismatch at position \(i): code has '\(codeName)', documentation has '\(docName)'"
                        )
                    )
                }
            }

            // Check parameter types
            if let codeType = codeParam.type, let docType = docParam.type {
                if !areTypesEquivalent(codeType, docType) {
                    inconsistencies.append(
                        Inconsistency(
                            type: .parameterTypeMismatch,
                            codeSignature: code,
                            docSignature: doc,
                            details:
                                "Parameter type mismatch for '\(codeParam.name ?? "param\(i)")': code has '\(codeType)', documentation has '\(docType)'"
                        )
                    )
                }
            }
        }

        return inconsistencies
    }

    private func areTypesEquivalent(_ type1: String, _ type2: String) -> Bool {
        // Normalize types for comparison
        let normalized1 = type1.lowercased().trimmingCharacters(
            in: .whitespaces
        )
        let normalized2 = type2.lowercased().trimmingCharacters(
            in: .whitespaces
        )

        // Direct match
        if normalized1 == normalized2 { return true }

        // Common type aliases
        let typeAliases: [Set<String>] = [
            ["int", "integer", "number"],
            ["str", "string"],
            ["bool", "boolean"],
            ["dict", "dictionary", "map", "object"],
            ["list", "array"],
            ["float", "double", "decimal"],
        ]

        for aliasSet in typeAliases {
            if aliasSet.contains(normalized1) && aliasSet.contains(normalized2)
            {
                return true
            }
        }

        return false
    }
}
