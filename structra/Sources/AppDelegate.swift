//
//  AppDelegate.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/18/25.
//

import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuCoordinator: MenuCoordinator!

    func applicationDidFinishLaunching(_ _: Notification) {
        let modules: [AppMenuModule] = [
            AppModule(),
            HelpModule()
        ]
        menuCoordinator = MenuCoordinator(modules: modules)
        menuCoordinator.setupMenus()
    }
}
