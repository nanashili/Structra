//
//  HelpModule.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/18/25.
//

import AppKit

/// A simple “Help” menu, because your users are definitely going to read documentation
/// and not just rage-click “Report an Issue…” after breaking everything.
/// Static entries only, because macOS menus haven’t heard of context or relevance.
struct HelpModule: AppMenuModule {

    /// Builds the “Help” NSMenuItem like it’s 1999.
    var menuItem: NSMenuItem {
        // Create the parent item. No action, no target, just vibes.
        let item = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")

        // Because NSMenu is still initialized with a title, as if that matters to anyone but VoiceOver.
        let submenu = NSMenu(title: "Help")
        item.submenu = submenu

        // Add the only piece of documentation anyone will pretend to open.
        submenu.addItem(
            withTitle: "Structra User Guide",
            action: nil,  // No handler, because who actually reads guides?
            keyEquivalent: "?"  // Also opens macOS Help instead. LOL.
        )

        submenu.addItem(.separator())

        // The only menu item people will actually click—out of frustration.
        submenu.addItem(
            withTitle: "Report an Issue…",
            action: nil,
            keyEquivalent: ""
        )

        return item
    }

    var dataProviders: [MenuDataProvider] { [] }
}
