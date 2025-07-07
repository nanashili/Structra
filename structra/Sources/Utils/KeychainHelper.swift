//
//  KeychainHelper.swift
//  structra
//
//  Created by Nanashi Li on 7/7/25.
//

import Foundation
import Security

/// A utility for securely interacting with the system Keychain.
struct KeychainHelper {

    /// Saves a piece of data securely to the Keychain. It will overwrite any existing data for the given key.
    /// - Parameters:
    ///   - data: The data to be saved. Must be convertible to `Data`.
    ///   - service: A unique identifier for your app's service (e.g., your app's bundle ID).
    ///   - account: The key for the data (e.g., "openai_api_key").
    static func save(data: Data, service: String, account: String) {
        delete(service: service, account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]

        // Add the new item to the keychain.
        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            print("Error saving to Keychain: \(status)")
        }
    }

    /// Reads a piece of data from the Keychain.
    /// - Returns: The stored data, or `nil` if it doesn't exist or an error occurs.
    static func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            return dataTypeRef as? Data
        } else {
            if status != errSecItemNotFound {
                print("Error reading from Keychain: \(status)")
            }
            return nil
        }
    }

    /// Deletes a piece of data from the Keychain.
    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        SecItemDelete(query as CFDictionary)
    }
}
