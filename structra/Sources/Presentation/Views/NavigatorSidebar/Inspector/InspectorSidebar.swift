//
//  InspectorSidebar.swift
//  structra
//
//  Created by Nanashi Li on 6/26/25.
//

import SwiftUI

// The main Inspector View that handles showing the different
// views that the inspector has like the file inspector, history and
// Quick Help.
struct InspectorSidebar: View {
    /// The active state of the control
    @Environment(\.controlActiveState)
    private var activeState

    /// The current selection
    @State
    private var selection: Int = 0

    /// The view body
    var body: some View {
        VStack {
            NoSelectionView()
        }
        .frame(
            minWidth: 250,
            idealWidth: 260,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .top
        )
        .opacity(activeState == .inactive ? 0.45 : 1)
    }
}
