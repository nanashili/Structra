//
//  Workspace+AIClient.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import Combine
import Foundation
import ObjectiveC

extension WorkspaceManager {
    private static var aiResultPublisherKey: UInt8 = 0

    // MARK: - Public AI Publisher

    /// A publisher that emits results from AI generation tasks.
    ///
    /// The UI layer of the application can subscribe to this publisher to receive real-time
    /// updates. This allows for streaming the AI's response directly to the user, showing
    /// progress, and handling final success or failure states gracefully.
    public var aiResultPublisher: PassthroughSubject<AIGenerationResult, Never>
    {
        if let publisher = objc_getAssociatedObject(
            self,
            &Self.aiResultPublisherKey
        ) as? PassthroughSubject<AIGenerationResult, Never> {
            return publisher
        }

        let newPublisher = PassthroughSubject<AIGenerationResult, Never>()
        objc_setAssociatedObject(
            self,
            &Self.aiResultPublisherKey,
            newPublisher,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return newPublisher
    }

    // MARK: - Private AI Client

    /// A private, lazily-instantiated client for performing AI tasks.
    /// This client is configured by dynamically loading all available API keys
    /// that the user has securely saved in the Keychain.
    private var aiClient: AIClient {
        let keysAndProviders = ClientTarget.AIProvider.allCases.compactMap {
            provider -> (ClientTarget.AIProvider, String)? in
            if let apiKey = AppSettings.loadApiKey(for: provider) {
                return (provider, apiKey)
            }
            return nil
        }

        let apiKeys = Dictionary(uniqueKeysWithValues: keysAndProviders)

        let config = AIClientConfiguration(apiKeys: apiKeys)
        return AIClient(configuration: config)
    }

    // MARK: - Public AI Actions

    /// Initiates a job to generate documentation for a given project node.
    ///
    /// This function is designed to be called from a UI action (e.g., a context menu).
    /// It performs the entire operation asynchronously in a background task and publishes
    /// all outcomes—including text chunks, errors, and completion signals—to the shared
    /// `aiResultPublisher`.
    ///
    /// - Parameter node: The `ProjectNode` representing the file to be documented.
    public func initiateDocumentationGeneration(
        for node: ProjectNode,
        detailLevel: String
    ) {
        Task {
            guard !node.type.isFolder else {
                aiResultPublisher.send(.failure(AIError.folderNotSupported))
                return
            }

            let language = language(for: node.url)

            guard
                let content = try? String(contentsOf: node.url, encoding: .utf8)
            else {
                let error = AIClientError.fileReadError(node)
                self.aiResultPublisher.send(.failure(error))
                return
            }

            let inputData: [String: Any] = [
                "fileName": node.name,
                "content": content,
                "language": language,
                "detailLevel": detailLevel,
            ]

            do {
                let job = PromptJob(
                    target: .thirdParty(provider: .gemini),
                    inputData: inputData,
                    promptTemplateKey: "swift-file-doc.md"
                )

                let stream = aiClient.stream(job: job)

                var fullResponse = ""
                for try await chunk in stream {
                    fullResponse += chunk.content
                    aiResultPublisher.send(.chunk(chunk.content))
                }

                aiResultPublisher.send(.success)
            } catch {
                aiResultPublisher.send(.failure(error))
            }
        }
    }

    private func language(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "swift":
            return "swift"
        case "js", "jsx", "ts", "tsx":
            return "javascript"
        case "py":
            return "python"
        case "java":
            return "java"
        case "kt", "kts":
            return "kotlin"
        case "rb":
            return "ruby"
        case "go":
            return "go"
        case "rs":
            return "rust"
        case "html":
            return "html"
        case "css":
            return "css"
        default:
            // A safe fallback for unknown file types.
            return "plaintext"
        }
    }
}
