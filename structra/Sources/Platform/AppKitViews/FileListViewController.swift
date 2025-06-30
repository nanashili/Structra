//
//  FileListViewController.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/18/25.
//

import Cocoa

class FileListViewController: NSViewController, NSTableViewDataSource,
    NSTableViewDelegate
{
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let files = [
        "App.swift", "ContentView.swift", "NetworkManager.swift", "Utils.swift",
    ]

    override func loadView() {
        // embed tableView in scrollView
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        self.view = scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // 1 column
        let column = NSTableColumn(identifier: .init("FileColumn"))
        column.title = "Files"
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.delegate = self
        tableView.dataSource = self
        tableView.selectionHighlightStyle = .sourceList
    }

    // MARK: datasource
    func numberOfRows(in tableView: NSTableView) -> Int {
        files.count
    }

    func tableView(
        _ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?,
        row: Int
    ) -> NSView? {
        let cell =
            tableView.makeView(withIdentifier: .init("FileCell"), owner: self)
            as? NSTableCellView
            ?? NSTableCellView()
        cell.identifier = .init("FileCell")
        cell.textField = NSTextField(labelWithString: files[row])
        cell.textField?.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        cell.imageView = NSImageView(
            image: NSImage(
                systemSymbolName: "doc.text",
                accessibilityDescription: nil
            )!
        )
        cell.imageView?.symbolConfiguration = .init(
            pointSize: 12,
            weight: .regular
        )
        cell.addSubview(cell.imageView!)
        cell.addSubview(cell.textField!)
        // layout
        cell.imageView?.frame = CGRect(x: 4, y: 2, width: 16, height: 16)
        cell.textField?.frame = CGRect(
            x: 26,
            y: 0,
            width: tableView.bounds.width - 30,
            height: 20
        )
        return cell
    }
}
