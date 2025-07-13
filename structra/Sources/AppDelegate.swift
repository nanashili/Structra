//
//  AppDelegate.swift
//  structra
//
//  Created by Nanashi Li on 6/18/25.
//

import Catalyst
import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuCoordinator: MenuCoordinator!

    public let catalyst: UpdateService

    override init() {

        guard let bundleId = Bundle.main.bundleIdentifier else {
            fatalError(
                "Could not determine bundle identifier. The app cannot be updated."
            )
        }

        let config = UpdateConfiguration(
            feedURL: URL(
                string:
                    "https://raw.githubusercontent.com/nanashili/Testing/refs/heads/main/update.json"
            )!,
            appName: "Structra",
            bundleIdentifier: bundleId
        )
        self.catalyst = UpdateService(configuration: config)
        super.init()
    }

    func applicationDidFinishLaunching(_ _: Notification) {
        let modules: [AppMenuModule] = [
            AppModule(),
            HelpModule(),
        ]
        menuCoordinator = MenuCoordinator(modules: modules)
        menuCoordinator.setupMenus()
        
        catalyst.startCheckingForUpdates()
    }
}
