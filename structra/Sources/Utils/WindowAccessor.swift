//
//  WindowAccessor.swift
//  structra
//
//  Created by Nanashi Li on 6/18/25.
//

import AppKit
import SwiftUI

/// A duct-tape view that lets SwiftUI pretend it can actually interact with AppKit.
/// Because SwiftUI sure as hell isn’t going to give you a window reference directly.
///
/// `WindowAccessor` is here to answer the age-old question: “Can I please just get the damn NSWindow?”
///
/// Spoiler: No. You have to embed this empty NSView and then *hope* SwiftUI has finished attaching it.
struct WindowAccessor: NSViewRepresentable {

    var callback: (NSWindow) -> Void

    /// Creates a hollow NSView just to exploit `window` linkage—because nothing says "modern declarative UI"
    /// like embedding invisible NSViews to fish for UIKit/AppKit context.
    func makeNSView(context: Context) -> NSView {
        let v = NSView()

        // DispatchQueue.main.async: because SwiftUI initializes in 19 broken phases
        // and this view doesn’t get a window immediately. Neat, huh?
        DispatchQueue.main.async {
            if let window = v.window {
                callback(window)
            }
        }

        return v
    }

    /// Updates the NSView, in case SwiftUI throws this view in a blender and reattaches it at runtime.
    /// Run the same async window voodoo again, just in case.
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                callback(window)
            }
        }
    }
}
