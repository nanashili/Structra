//
//  EditorWindowController+Toolbar.swift
//  structra
//
//  Created by Nanashi Li on 6/26/25.
//  Refactored 2025/07/12 for performance and maintainability.
//

import Combine
import SwiftUI

// MARK: - NSToolbarDelegate
extension EditorWindowController: NSToolbarDelegate {

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem
        .Identifier]
    {
        [
            .toggleNavigator,
            .flexibleSpace,
            .sidebarTrackingSeparator,
            .flexibleSpace,
            .itemListTrackingSeparator,
            .flexibleSpace,
            .toggleInspector,
        ]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem
        .Identifier]
    {
        return toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {

        switch itemIdentifier {
        case .toggleNavigator:
            return createToggleNavigatorItem()
        case .toggleInspector:
            return createToggleInspectorItem()
        case .sidebarTrackingSeparator, .itemListTrackingSeparator:
            return createTrackingSeparatorItem(for: itemIdentifier)
        default:
            return nil
        }
    }

    // MARK: - Item Creation Methods

    private func createToggleNavigatorItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .toggleNavigator)
        item.label = "Navigator"
        item.paletteLabel = "Navigator"
        item.toolTip = "Hide or show the Navigator"
        item.isBordered = true

        // Create and configure the button
        let button = NSButton()
        button.image = NSImage(
            systemSymbolName: "sidebar.leading",
            accessibilityDescription: "Navigator"
        )
        button.image?.isTemplate = true
        button.bezelStyle = .texturedRounded
        button.target = self
        button.action = #selector(toggleNavigatorPane)

        item.view = button
        return item
    }

    private func createToggleInspectorItem() -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: .toggleInspector)
        item.label = "Inspector"
        item.paletteLabel = "Inspector"
        item.toolTip = "Hide or show the Inspector"
        item.isBordered = true

        // Create and configure the button
        let button = NSButton()
        button.image = NSImage(
            systemSymbolName: "sidebar.trailing",
            accessibilityDescription: "Inspector"
        )
        button.image?.isTemplate = true
        button.bezelStyle = .texturedRounded
        button.target = self
        button.action = #selector(toggleInspectorPane)

        item.view = button
        return item
    }

    private func createTrackingSeparatorItem(
        for identifier: NSToolbarItem.Identifier
    ) -> NSToolbarItem? {
        guard let splitVC = contentViewController as? NSSplitViewController
        else { return nil }

        let dividerIndex = (identifier == .sidebarTrackingSeparator) ? 0 : 1
        return NSTrackingSeparatorToolbarItem(
            identifier: identifier,
            splitView: splitVC.splitView,
            dividerIndex: dividerIndex
        )
    }

    // MARK: - Actions

    @objc func toggleNavigatorPane() {
        guard
            let splitVC = self.contentViewController as? NSSplitViewController,
            let navigatorPane = splitVC.splitViewItems.first(where: {
                $0.viewController.identifier == .navigatorSidebar
            })
        else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.allowsImplicitAnimation = true
            navigatorPane.animator().isCollapsed.toggle()
        }
    }

    @objc func toggleInspectorPane() {
        guard
            let splitVC = self.contentViewController as? NSSplitViewController,
            let inspectorPane = splitVC.splitViewItems.first(where: {
                $0.viewController.identifier == .inspectorSidebar
            })
        else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.allowsImplicitAnimation = true
            inspectorPane.animator().isCollapsed.toggle()
        }
    }
}

// MARK: - Identifier Definitions
extension NSUserInterfaceItemIdentifier {
    static let navigatorSidebar = NSUserInterfaceItemIdentifier(
        "NavigatorSidebar"
    )
    static let inspectorSidebar = NSUserInterfaceItemIdentifier(
        "InspectorSidebar"
    )
}

extension NSToolbarItem.Identifier {
    static let toggleNavigator = NSToolbarItem.Identifier("ToggleNavigator")
    static let toggleInspector = NSToolbarItem.Identifier("ToggleInspector")
    static let itemListTrackingSeparator = NSToolbarItem.Identifier(
        "ItemListTrackingSeparator"
    )
}
