//
//  HyperParser+RoleHints.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

// Pre-computed role hint patterns for faster matching
public var roleHintRules: [RoleHintRule] = [
    // --- Exact Filename Rules (Highest Confidence, Language Agnostic) ---
    .init(
        target: .fileName,
        matchType: .exact,
        pattern: "Package.swift",
        hint: "package-manifest",
        score: 120
    ),
    .init(
        target: .fileName,
        matchType: .exact,
        pattern: "package.json",
        hint: "package-manifest",
        score: 120
    ),
    .init(
        target: .fileName,
        matchType: .exact,
        pattern: "go.mod",
        hint: "package-manifest",
        score: 120
    ),
    .init(
        target: .fileName,
        matchType: .exact,
        pattern: "requirements.txt",
        hint: "dependency-manifest",
        score: 120
    ),
    .init(
        target: .fileName,
        matchType: .exact,
        pattern: "pom.xml",
        hint: "package-manifest",
        score: 120
    ),
    .init(
        target: .fileName,
        matchType: .exact,
        pattern: "Podfile",
        hint: "dependency-manifest",
        score: 120
    ),
    .init(
        target: .fileName,
        matchType: .exact,
        pattern: "Gemfile",
        hint: "dependency-manifest",
        score: 120
    ),
    .init(
        target: .fileName,
        matchType: .exact,
        pattern: "Dockerfile",
        hint: "container-definition",
        score: 120
    ),
    .init(
        target: .fileName,
        matchType: .exact,
        pattern: "docker-compose.yml",
        hint: "container-orchestration",
        score: 120
    ),
    .init(
        target: .fileName,
        matchType: .exact,
        pattern: "Makefile",
        hint: "build-script",
        score: 110
    ),
    .init(
        target: .fileName,
        matchType: .exact,
        pattern: ".env",
        hint: "environment-config",
        score: 110
    ),
    .init(
        target: .fileName,
        matchType: .exact,
        pattern: "README.md",
        hint: "documentation",
        score: 110
    ),
    .init(
        target: .fileName,
        matchType: .exact,
        pattern: "LICENSE",
        hint: "license",
        score: 110
    ),
    .init(
        target: .fileName,
        matchType: .exact,
        pattern: "CONTRIBUTING.md",
        hint: "documentation",
        score: 110
    ),

    // --- Directory-based Rules (High Confidence, Language Agnostic) ---
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/services/",
        hint: "service",
        score: 100
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/viewmodels/",
        hint: "viewmodel",
        score: 100
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/controllers/",
        hint: "controller",
        score: 100
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/models/",
        hint: "model",
        score: 100
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/repositories/",
        hint: "repository",
        score: 100
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/networking/",
        hint: "networking",
        score: 100
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/tests/",
        hint: "testing",
        score: 100
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/views/",
        hint: "view",
        score: 90
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/components/",
        hint: "ui-component",
        score: 90
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/persistence/",
        hint: "storage",
        score: 90
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/database/",
        hint: "storage",
        score: 90
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/coordinators/",
        hint: "navigation",
        score: 90
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/routes/",
        hint: "routing",
        score: 90
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/middleware/",
        hint: "middleware",
        score: 90
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/utils/",
        hint: "utility",
        score: 80
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/helpers/",
        hint: "utility",
        score: 80
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/extensions/",
        hint: "extension",
        score: 80
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/config/",
        hint: "configuration",
        score: 80
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/scripts/",
        hint: "script",
        score: 80
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/assets/",
        hint: "asset",
        score: 80
    ),
    .init(
        target: .directoryPath,
        matchType: .contains,
        pattern: "/docs/",
        hint: "documentation",
        score: 80
    ),

    // --- Filename Stem Suffix Rules (Medium Confidence, Language Agnostic) ---
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "ViewModel",
        hint: "viewmodel",
        score: 70
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "Service",
        hint: "service",
        score: 70
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "Controller",
        hint: "controller",
        score: 70
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "Repository",
        hint: "repository",
        score: 70
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "Model",
        hint: "model",
        score: 70
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "Entity",
        hint: "model",
        score: 70
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "Tests",
        hint: "testing",
        score: 70
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "Spec",
        hint: "testing",
        score: 70
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "TestCase",
        hint: "testing",
        score: 70
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "View",
        hint: "view",
        score: 60
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "ViewController",
        hint: "view",
        score: 60
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "Component",
        hint: "ui-component",
        score: 60
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "Coordinator",
        hint: "navigation",
        score: 60
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "Router",
        hint: "routing",
        score: 60
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "Manager",
        hint: "manager",
        score: 60
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "Factory",
        hint: "factory",
        score: 60
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "Policy",
        hint: "policy",
        score: 60
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "Request",
        hint: "networking-model",
        score: 60
    ),
    .init(
        target: .fileNameStem,
        matchType: .suffix,
        pattern: "Response",
        hint: "networking-model",
        score: 60
    ),

    // --- Filename Contains Rules (Lower Confidence, Language Agnostic) ---
    .init(
        target: .fileName,
        matchType: .contains,
        pattern: "config",
        hint: "configuration",
        score: 40
    ),
    .init(
        target: .fileName,
        matchType: .contains,
        pattern: "api",
        hint: "networking",
        score: 40
    ),
    .init(
        target: .fileName,
        matchType: .contains,
        pattern: "auth",
        hint: "authentication",
        score: 40
    ),
    .init(
        target: .fileName,
        matchType: .contains,
        pattern: "route",
        hint: "routing",
        score: 30
    ),
    .init(
        target: .fileName,
        matchType: .contains,
        pattern: "network",
        hint: "networking",
        score: 30
    ),
    .init(
        target: .fileName,
        matchType: .contains,
        pattern: "database",
        hint: "storage",
        score: 30
    ),
    .init(
        target: .fileName,
        matchType: .contains,
        pattern: "cache",
        hint: "caching",
        score: 30
    ),
    .init(
        target: .fileName,
        matchType: .contains,
        pattern: "job",
        hint: "background-job",
        score: 30
    ),
    .init(
        target: .fileName,
        matchType: .contains,
        pattern: "worker",
        hint: "background-job",
        score: 30
    ),
]
