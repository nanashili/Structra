//
//  MenuModule.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/18/25.
//

import AppKit

/// Provides a top-level NSMenuItem (with submenu) and zero or more dynamic child providers,
/// all manually assembled like it’s 1995 and Interface Builder never existed.
protocol AppMenuModule {

    /// The NSMenuItem to insert into NSApp.mainMenu.
    /// God forbid you use anything declarative for this—welcome back to manually populating trees.
    var menuItem: NSMenuItem { get }

    /// Dynamic submenu providers, because having menus change live is
    /// something Apple never officially documented since Carbon.
    var dataProviders: [MenuDataProvider] { get }
}
