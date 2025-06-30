//
//  String.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/30/25.
//

import CryptoKit
import Foundation

extension String {
    /// Returns the SHA256 hash of the string as a hex string.
    func sha256() -> String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
