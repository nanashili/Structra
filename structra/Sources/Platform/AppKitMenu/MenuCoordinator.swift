//
//  MenuCoordinator.swift
//  structra
//
//  Created by Nanashi Li on 6/18/25.
//

import AppKit
import Combine

final class MenuCoordinator {

    // All the menu modules this poor app relies on to feel native in 2025.
    private let modules: [AppMenuModule]

    // Combine’s version of ARC babysitting. Because obviously the compiler
    // couldn’t just make this easier for you.
    private var cancellables = Set<AnyCancellable>()

    /// Inject your sad, fragmented menu structure here.
    init(modules: [AppMenuModule]) {
        self.modules = modules
    }

    /// Builds the entire macOS menu structure because Apple refuses to
    /// give us one that "just works" without 400 lines of glue code.
    func setupMenus() {
        let mainMenu = NSMenu()
        // Setting this feels like loading firmware. Pray it works.
        NSApp.mainMenu = mainMenu

        // Insert each top-level item. Like a caveman dragging menu items into a bar.
        modules.forEach { module in
            mainMenu.addItem(module.menuItem)
        }

        modules
            .flatMap { $0.dataProviders }  // Functional chaining: looks elegant, fails silently.
            .forEach { provider in
                guard
                    let parent = NSApp.mainMenu?
                        .item(withTitle: provider.menuIdentifier.rawValue),
                    let submenu = parent.submenu
                else {
                    // Menu not found? No log. No crash. Just silence. Classic macOS.
                    return
                }

                provider.itemsPublisher
                    .receive(on: DispatchQueue.main)
                    .sink { items in
                        submenu.removeAllItems()  // Because AppKit won’t update them unless you do it *manually*
                        items.forEach { submenu.addItem($0) }  // Again, no diffing, no batching. Pure Cocoa Hell.
                    }
                    .store(in: &cancellables)
            }
    }
}
