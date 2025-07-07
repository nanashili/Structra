//
//  AIClientConfiguration.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import Foundation

public struct AIClientConfiguration {
    let internalAPIEndpoint: URL
    let localhostBaseURL: URL
    private let apiKeys: [ClientTarget.AIProvider: String]
    let defaultHeaders: [String: String]

    public init(
        internalAPIEndpoint: URL = URL(
            string: "https://api.my-company.com/v1/ai"
        )!,
        localhostBaseURL: URL = URL(string: "http://localhost:11434")!,
        apiKeys: [ClientTarget.AIProvider: String] = [:],
        defaultHeaders: [String: String] = ["Content-Type": "application/json"]
    ) {
        self.internalAPIEndpoint = internalAPIEndpoint
        self.localhostBaseURL = localhostBaseURL
        self.apiKeys = apiKeys
        self.defaultHeaders = defaultHeaders
    }

    /// A safe way to retrieve an API key for a specific provider.
    func apiKey(for provider: ClientTarget.AIProvider) -> String? {
        return apiKeys[provider]
    }
}
