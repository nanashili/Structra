import Foundation
import OpenAI

/// Represents a single chunk from an OpenAI-compatible streaming API (like Gemini, Mistral).
struct OpenAIStreamResponse: Decodable {
    let choices: [Choice]
}

struct Choice: Decodable {
    let delta: Delta
}

struct Delta: Decodable {
    /// The actual text content of the chunk.
    /// It's optional because the very last chunk from the API might not have content.
    let content: String?
}

/// The primary client for interacting with various AI models and services.
///
/// `AIClient` acts as a unified interface that abstracts the complexities of communicating
/// with different AI providers, whether they are third-party APIs (like OpenAI, Claude),
/// internal backend services, or models running on localhost. It handles request routing,
/// authentication, prompt templating, and response streaming.
public final class AIClient {

    // MARK: - Properties

    /// The configuration object containing all necessary settings, such as API keys and endpoints.
    private let configuration: AIClientConfiguration

    /// The URLSession instance used for making network requests, particularly for services
    /// that don't have a dedicated Swift SDK.
    private let urlSession: URLSession

    /// The engine responsible for rendering final prompts from templates and input data.
    private let templateEngine: PromptTemplateEngine

    /// The dedicated client for OpenAI API calls, using the MacPaw/OpenAI SDK.
    /// This is initialized only if an OpenAI API key is provided in the configuration,
    /// allowing the rest of the app to function with other providers if the key is missing.
    private let openAIClient: OpenAI?

    // MARK: - Initializer

    /// Initializes a new instance of the `AIClient`.
    ///
    /// This setup configures the client with the necessary dependencies and conditionally
    /// initializes the OpenAI SDK based on the provided configuration.
    ///
    /// - Parameters:
    ///   - configuration: An `AIClientConfiguration` object containing API keys, endpoints, and other settings.
    ///   - urlSession: The `URLSession` instance to use for network requests. Defaults to `.shared`.
    ///   - templateEngine: The engine for processing prompt templates. Defaults to a new `PromptTemplateEngine`.
    public init(
        configuration: AIClientConfiguration,
        urlSession: URLSession = .shared,
        templateEngine: PromptTemplateEngine = PromptTemplateEngine()
    ) {
        self.configuration = configuration
        self.urlSession = urlSession
        self.templateEngine = templateEngine

        if let openAIKey = configuration.apiKey(for: .openAI) {
            let openAIConfig = OpenAI.Configuration(
                token: openAIKey,
                parsingOptions: .relaxed
            )
            self.openAIClient = OpenAI(configuration: openAIConfig)
        } else {
            self.openAIClient = nil
        }
    }

    // MARK: - Public API

    /// Performs a given AI job and streams the response back to the caller.
    ///
    /// This is the primary entry point for all AI requests. It takes a `PromptJob`,
    /// determines the correct destination (internal, localhost, or a third-party provider),
    /// and returns an `AsyncThrowingStream` that yields `AIResponseChunk`s as they arrive.
    ///
    /// - Parameter job: The `PromptJob` object that describes the work to be done, including the target,
    ///   prompt template, and input data.
    /// - Returns: An `AsyncThrowingStream` that provides a sequence of `AIResponseChunk`s.
    ///   The stream will finish successfully upon completion or throw an error if one occurs.
    public func stream(job: PromptJob) -> AsyncThrowingStream<
        AIResponseChunk, Error
    > {
        return AsyncThrowingStream { [weak self] continuation in
            guard let self = self else {
                continuation.finish()
                return
            }

            Task {
                do {
                    switch job.target {
                    case .thirdParty(let provider):
                        try await self.streamThirdParty(
                            job: job,
                            provider: provider,
                            continuation: continuation
                        )

                    case .internal, .localhost:
                        try await self.streamWithURLSession(
                            job: job,
                            continuation: continuation
                        )
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Streaming Handlers

    /// Routes jobs targeting third-party providers to the appropriate streaming implementation.
    ///
    /// This method acts as a sub-router. It checks the specific provider and decides whether
    /// to use a dedicated SDK (like for OpenAI) or fall back to a manual implementation.
    ///
    /// - Parameters:
    ///   - job: The `PromptJob` to be performed.
    ///   - provider: The specific `AIProvider` to target (e.g., OpenAI, Claude).
    ///   - continuation: The stream continuation to yield results to.
    /// - Throws: An error if the request setup fails (e.g., missing API key).
    private func streamThirdParty(
        job: PromptJob,
        provider: ClientTarget.AIProvider,
        continuation: AsyncThrowingStream<AIResponseChunk, Error>.Continuation
    ) async throws {
        switch provider {
        case .openAI:
            // If the provider is OpenAI, we use the dedicated handler that leverages the official SDK.
            try await streamWithOpenAISDK(job: job, continuation: continuation)

        case .claude, .mistral, .gemini, .llama:
            // For all other third-party providers, we fall back to the manual URLSession method.
            // This assumes they use a standard Server-Sent Events (SSE) stream.
            try await streamWithURLSession(job: job, continuation: continuation)
        }
    }

    /// Streams responses from the OpenAI API using the MacPaw/OpenAI SDK.
    ///
    /// This method leverages the SDK's built-in streaming capabilities, simplifying the process
    /// by handling network connections, request formatting, and stream parsing automatically.
    ///
    /// - Parameters:
    ///   - job: The `PromptJob` containing the details for the OpenAI request.
    ///   - continuation: The stream continuation to yield `AIResponseChunk`s to.
    /// - Throws: `AIClientError.missingConfiguration` if the OpenAI API key is not set.
    ///           `AIClientError.missingTemplateKey` if the job does not specify a prompt template.
    ///           Any error thrown by the `templateEngine` or the `openAIClient`.
    private func streamWithOpenAISDK(
        job: PromptJob,
        continuation: AsyncThrowingStream<AIResponseChunk, Error>.Continuation
    ) async throws {
        guard let openAIClient = self.openAIClient else {
            throw AIClientError.missingConfiguration(
                "OpenAI API key not configured."
            )
        }

        guard let templateKey = job.promptTemplateKey else {
            throw AIClientError.missingTemplateKey
        }

        let promptContent = try await templateEngine.render(
            key: templateKey,
            with: job.inputData
        )
        
        print(promptContent)

        let query = ChatQuery(
            messages: [.user(.init(content: .string(promptContent)))],
            model: .gpt3_5Turbo,
            stream: true
        )

        for try await result in openAIClient.chatsStream(query: query) {
            guard let content = result.choices.first?.delta.content else {
                continue
            }

            let chunk = AIResponseChunk(
                id: result.id,
                content: content,
                isFinal: false
            )
            continuation.yield(chunk)
        }
    }

    /// Streams responses by making a manual URLSession request and parsing Server-Sent Events (SSE).
    ///
    /// This method is the fallback for any provider that does not have a dedicated SDK implementation.
    /// It constructs a `URLRequest`, executes it, and manually parses the byte stream for SSE lines.
    ///
    /// - Parameters:
    ///   - job: The `PromptJob` to be performed.
    ///   - continuation: The stream continuation to yield results to.
    /// - Throws: `AIClientError.networkError` if the HTTP response is not successful (not 2xx).
    ///           Any error thrown by `buildRequest` or `urlSession.bytes(for:)`.
    private func streamWithURLSession(
        job: PromptJob,
        continuation: AsyncThrowingStream<AIResponseChunk, Error>.Continuation
    ) async throws {
        let request = try await buildRequest(for: job)

        let (bytes, response) = try await self.urlSession.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode)
        else {
            let error = AIClientError.networkError(
                underlyingError: NSError(
                    domain: "HTTPError",
                    code: (response as? HTTPURLResponse)?.statusCode ?? 500,
                    userInfo: nil
                )
            )
            throw error
        }

        let decoder = JSONDecoder()

        for try await line in bytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = line.dropFirst(6).trimmingCharacters(
                    in: .whitespaces
                )

                if jsonString == "[DONE]" { break }

                guard let data = jsonString.data(using: .utf8) else { continue }

                do {
                    let decodedResponse = try decoder.decode(
                        OpenAIStreamResponse.self,
                        from: data
                    )

                    if let textContent = decodedResponse.choices.first?.delta
                        .content
                    {
                        let chunk = AIResponseChunk(
                            id: UUID().uuidString,
                            content: textContent,
                            isFinal: false
                        )
                        continuation.yield(chunk)
                    }
                } catch {
                    print(
                        "⚠️ [AI] Stream decoding error: \(error.localizedDescription) on line: \(jsonString)"
                    )
                }
            }
        }
    }
    // MARK: - Private Request Building (for non-SDK calls)

    /// The main router for building a `URLRequest` for any target not handled by a dedicated SDK.
    ///
    /// - Parameter job: The `PromptJob` that needs a `URLRequest`.
    /// - Returns: A fully configured `URLRequest`.
    /// - Throws: An error if the request cannot be constructed (e.g., missing template key).
    private func buildRequest(for job: PromptJob) async throws -> URLRequest {
        switch job.target {
        case .internal:
            return try buildInternalRequest(job: job)
        case .localhost:
            return try await buildLocalhostRequest(job: job)
        case .thirdParty(let provider):
            return try await buildThirdPartyRequest(
                job: job,
                provider: provider
            )
        }
    }

    /// Builds a request for an internal backend service.
    ///
    /// This method assumes the internal API handles prompt templating itself and expects
    /// the raw, structured data from the job.
    ///
    /// - Parameter job: The `PromptJob` containing the data to be sent.
    /// - Returns: A configured `URLRequest` for the internal endpoint.
    /// - Throws: An error if the input data cannot be serialized to JSON.
    private func buildInternalRequest(job: PromptJob) throws -> URLRequest {
        var request = URLRequest(url: configuration.internalAPIEndpoint)
        request.httpMethod = "POST"
        // The internal API receives the raw, structured input data directly.
        // Prompting and model interaction are handled server-side.
        request.httpBody = try JSONSerialization.data(
            withJSONObject: job.inputData
        )
        // Apply any default headers from the configuration.
        configuration.defaultHeaders.forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }
        // TODO: Add any internal-specific authentication headers here.
        return request
    }

    /// Builds a request for a model running on localhost (e.g., via Ollama).
    ///
    /// This method renders the prompt locally and constructs a JSON payload that is
    /// typical for local inference servers.
    ///
    /// - Parameter job: The `PromptJob` to be performed.
    /// - Returns: A configured `URLRequest` for the localhost endpoint.
    /// - Throws: `AIClientError.missingTemplateKey` or errors from the template engine.
    private func buildLocalhostRequest(job: PromptJob) async throws
        -> URLRequest
    {
        guard let templateKey = job.promptTemplateKey else {
            throw AIClientError.missingTemplateKey
        }

        let promptContent = try await templateEngine.render(
            key: templateKey,
            with: job.inputData
        )
        let url = configuration.localhostBaseURL.appendingPathComponent(
            "/api/generate"
        )

        let payload: [String: Any] = [
            "model": "llama3",
            "prompt": promptContent,
            "stream": true,
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        configuration.defaultHeaders.forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }
        return request
    }

    /// Builds a request for a third-party provider that doesn't have a dedicated SDK.
    ///
    /// - Parameters:
    ///   - job: The `PromptJob` to be performed.
    ///   - provider: The specific `AIProvider` to target.
    /// - Returns: A configured `URLRequest` with the correct endpoint, body, and authentication.
    /// - Throws: `AIClientError.missingConfiguration` if the API key is missing, or other errors
    ///   from template rendering or payload building.
    private func buildThirdPartyRequest(
        job: PromptJob,
        provider: ClientTarget.AIProvider
    ) async throws -> URLRequest {
        guard let apiKey = configuration.apiKey(for: provider) else {
            throw AIClientError.missingConfiguration(
                "API Key for \(provider.rawValue) not found."
            )
        }
        guard let templateKey = job.promptTemplateKey else {
            throw AIClientError.missingTemplateKey
        }

        let promptContent = try await templateEngine.render(
            key: templateKey,
            with: job.inputData
        )
        
        print(promptContent)

        let (url, body) = try buildProviderPayload(
            provider: provider,
            prompt: promptContent
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        configuration.defaultHeaders.forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }
        request.setValue(
            "Bearer \(apiKey)",
            forHTTPHeaderField: "Authorization"
        )

        return request
    }

    /// A helper function to create the correct JSON payload and identify the correct URL
    /// for each non-SDK third-party provider.
    ///
    /// - Parameters:
    ///   - provider: The `AIProvider` for which to build the payload.
    ///   - prompt: The final, rendered prompt string.
    /// - Returns: A tuple containing the target `URL` and the `Data` of the JSON payload.
    /// - Throws: An error if the payload cannot be serialized to JSON.
    /// - Important: This function will `fatalError` if called for `.openAI`, as OpenAI requests
    ///   must be handled exclusively by `streamWithOpenAISDK` to enforce the use of the SDK.
    private func buildProviderPayload(
        provider: ClientTarget.AIProvider,
        prompt: String
    ) throws -> (URL, Data) {
        let payload: [String: Any]
        let url: URL

        switch provider {
        case .openAI:
            fatalError(
                "OpenAI requests must be handled by the streamWithOpenAISDK method."
            )

        case .claude:
            url = URL(string: "https://api.anthropic.com/v1/messages")!
            payload = [
                "model": "claude-3-opus-20240229",
                "max_tokens": 4096,
                "messages": [["role": "user", "content": prompt]],
                "stream": true,
            ]

        case .mistral:
            url = URL(string: "https://api.mistral.ai/v1/chat/completions")!
            payload = [
                "model": "mistral-large-latest",
                "messages": [["role": "user", "content": prompt]],
                "stream": true,
            ]
        case .gemini, .llama:
            url = URL(
                string:
                    "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
            )!
            payload = [
                "model": "gemini-2.5-flash",
                "messages": [["role": "user", "content": prompt]],
                "stream": true,
            ]
        }

        let data = try JSONSerialization.data(withJSONObject: payload)
        return (url, data)
    }
}
