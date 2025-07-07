//
//  AppModule.swift
//  structra
//
//  Created by Nanashi Li on 6/18/25.
//

import AppKit

/// Represents the “App” menu. You know, the one Apple *demands* you put first,
/// filled with legacy crap no modern user ever intentionally clicks.
struct AppModule: AppMenuModule {

    var menuItem: NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu()

        item.submenu = menu

        menu.addItem(
            withTitle: "About Structa",  // Because this is the only branding Apple *lets* you have.
            action: #selector(NSApp.orderFrontStandardAboutPanel(_:)),  // Yes, this selector hasn’t changed since NeXTSTEP.
            keyEquivalent: ""  // Why would we shortcut this? No one’s ever excited about About dialogs.
        )

        menu.addItem(.separator())
        
        menu.addItem(
            withTitle: "Quit",  // The only menu item that matters.
            action: #selector(NSApp.terminate(_:)),
            keyEquivalent: "q"
        )

        return item
    }

    var dataProviders: [MenuDataProvider] { [] }
}
