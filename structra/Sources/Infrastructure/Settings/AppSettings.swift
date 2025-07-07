//
//  AppSettings.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import Foundation

/// A centralized manager for handling persistent user settings.
/// Non-sensitive data is stored in UserDefaults. Sensitive data is stored in the Keychain.
struct AppSettings {

    // MARK: - Keys
    private static let hasCompletedWalkthroughKey = "hasCompletedWalkthrough"
    private static let clientTargetKey = "clientTarget"
    private static let apiConfigurationKey = "apiConfiguration"

    private static let keychainService = "com.structra"

    // MARK: - Walkthrough Status
    static var hasCompletedWalkthrough: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedWalkthroughKey) }
        set {
            UserDefaults.standard.set(
                newValue,
                forKey: hasCompletedWalkthroughKey
            )
        }
    }

    // MARK: - Configuration Management

    /// Saves the configuration for a third-party provider.
    /// The API key is saved to the Keychain, and the rest of the config is saved to UserDefaults.
    static func saveThirdPartyConfiguration(
        target: ClientTarget,
        apiKey: String,
        configuration: [String: String]
    ) {
        guard case .thirdParty(let provider) = target else { return }

        let apiKeyData = Data(apiKey.utf8)
        let accountKey = "\(provider.rawValue.lowercased())_api_key"
        KeychainHelper.save(
            data: apiKeyData,
            service: keychainService,
            account: accountKey
        )

        saveConfiguration(target: target, configuration: configuration)
    }

    /// Saves configuration for non-sensitive targets like localhost.
    static func saveConfiguration(
        target: ClientTarget,
        configuration: [String: String]
    ) {
        let encoder = JSONEncoder()

        if let encodedTarget = try? encoder.encode(target) {
            UserDefaults.standard.set(encodedTarget, forKey: clientTargetKey)
        }

        if let encodedConfig = try? encoder.encode(configuration) {
            UserDefaults.standard.set(
                encodedConfig,
                forKey: apiConfigurationKey
            )
        }
    }

    /// Loads the saved client target.
    static func loadClientTarget() -> ClientTarget? {
        guard let data = UserDefaults.standard.data(forKey: clientTargetKey)
        else { return nil }
        return try? JSONDecoder().decode(ClientTarget.self, from: data)
    }

    /// Loads the saved configuration dictionary from UserDefaults.
    static func loadApiConfiguration() -> [String: String]? {
        guard let data = UserDefaults.standard.data(forKey: apiConfigurationKey)
        else { return nil }
        return try? JSONDecoder().decode([String: String].self, from: data)
    }

    /// Loads a third-party API key securely from the Keychain.
    static func loadApiKey(for provider: ClientTarget.AIProvider) -> String? {
        let accountKey = "\(provider.rawValue.lowercased())_api_key"
        guard
            let apiKeyData = KeychainHelper.read(
                service: keychainService,
                account: accountKey
            )
        else {
            return nil
        }
        return String(data: apiKeyData, encoding: .utf8)
    }
}
