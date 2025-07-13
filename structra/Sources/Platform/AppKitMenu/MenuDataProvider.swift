//
//  MenuDataProvider.swift
//  structra
//
//  Created by Nanashi Li on 6/18/25.
//

import AppKit
import Combine

/// Feeds dynamic items into an existing submenu because you weren’t already juggling enough state.
/// Requires a matching `menuIdentifier` or your submenu silently breaks like half of macOS APIs.
protocol MenuDataProvider: AnyObject {

    /// Must match NSMenuItem.identifier. Good luck debugging this when it doesn’t.
    var menuIdentifier: NSUserInterfaceItemIdentifier { get }

    /// A Combine publisher that will eventually produce menu items
    /// (or die quietly in a background thread when Combine gives up).
    var itemsPublisher: AnyPublisher<[NSMenuItem], Never> { get }
}
