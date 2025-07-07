//
//  EditorSplitViewController.swift
//  structra
//
//  Created by Nanashi Li on 6/18/25.
//

import AppKit
import Combine

class EditorSplitViewController: NSSplitViewController {

    /// - Note: Before calling viewDidAppear, received size is kind of minimum size.
    /// because it is not what user intends, we would like to skip such a default value to be persisted.
    private var calledViewDidAppear: Bool = false

    /// - Parameter prefs: The preferences model
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    /// Initialize `AuroraSplitViewController`
    ///
    /// - Parameter coder: The coder
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// view did appear
    override func viewDidAppear() {
        super.viewDidAppear()
        calledViewDidAppear = true
    }

    /// split view did resize subviews
    ///
    /// - Parameter notification: The notification
    override func splitViewDidResizeSubviews(_ notification: Notification) {
        if !calledViewDidAppear {
            return
        }

        // Workaround
        // this method `splitViewDidResizeSubviews` is also called when current window is about to be closed.
        // then, somehow splitViewItem size is not correct (like set to zero).
        // so I would like to skip the case some of the splitViewItems has zero size.
        guard splitView.subviews.isEmpty == false, splitView.subviews.allSatisfy({ $0.frame.width != .zero }) else {
            return
        }
    }
}
