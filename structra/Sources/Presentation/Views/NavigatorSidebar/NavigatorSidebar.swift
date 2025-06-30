//
//  NavigatorSidebar.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/26/25.
//

import OSLog
import SwiftUI

/// The sidebar of the navigator.
struct NavigatorSidebar: View {

    /// Selections
    @State
    public var selections: [Int] = [0]

    /// Toolbar padding
    private let toolbarPadding: Double = -8.0

    /// Logger
    let logger = Logger(
        subsystem: "com.auroraeditor",
        category: "Navigator Sidebar"
    )

    /// The view body.
    var body: some View {
        ForEach(Array(selections.enumerated()), id: \.offset) { index, _ in
            sidebarModule(toolbar: index)
        }
        .padding(.top, -30)
        .padding(.leading, 0)
        .padding(.top, 30)
        .padding(.leading, 0)
    }

    /// Sidebar module
    ///
    /// - Parameter toolbar: The toolbar number
    ///
    /// - Returns: The sidebar module.
    func sidebarModule(toolbar: Int) -> some View {
        // swiftlint:disable:previous function_body_length
        sidebarModuleContent(toolbar: toolbar)
    }

    /// Sidebar module content
    ///
    /// - Parameter toolbar: The toolbar number
    ///
    /// - Returns: The sidebar module content.
    func sidebarModuleContent(toolbar: Int) -> some View {
        VStack {
            switch selections[toolbar] {
            case 0:
                ProjectNavigator()
            default:
                needsImplementation
            }
        }
    }

    /// Needs implementation view
    var needsImplementation: some View {
        VStack(alignment: .center) {
            HStack {
                Spacer()
                Text("Needs Implementation")
                Spacer()
            }
        }
        .frame(maxHeight: .infinity)
    }
}
