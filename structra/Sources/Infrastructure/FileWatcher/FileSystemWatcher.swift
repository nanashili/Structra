//
//  FileSystemWatcher.swift
//  structra
//
//  Created by Nanashi Li on 6/19/25.
//

import Cocoa
import Foundation
import OSLog

// Every time a file does something, this struct holds the trauma.
// No 'Sendable' here. We manage our own thread safety like adults.
public struct FileEvent {
    let path: String
    let flags: FSEventStreamEventFlags
    let id: FSEventStreamEventId
    let metadata: NodeMetadata?

    var isCreated: Bool {
        (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated))
            != 0
    }

    var isRemoved: Bool {
        (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRemoved))
            != 0
    }

    var isModified: Bool {
        (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified))
            != 0
            || (flags
                & FSEventStreamEventFlags(
                    kFSEventStreamEventFlagItemInodeMetaMod
                )) != 0
    }

    var isRenamed: Bool {
        (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed))
            != 0
    }
}

class FileSystemWatcher {

    // Of course we need a C-style pointer ref in 2025. Thanks Swift team. Really feels modern.
    private var eventStream: FSEventStreamRef?

    // What are we watching? Our sanity dissolve? No, just file paths. Boring.
    private let watchedPaths: [String]

    // A simple closure. We'll handle dispatching to the main thread ourselves, thank you very much.
    private let eventHandler: ([FileEvent]) -> Void

    // DispatchQueue – because it's been getting the job done for a decade.
    private let eventQueue = DispatchQueue(
        label: "com.filewatcher.eventQueue",
        qos: .utility
    )

    private var eventBuffer = [FileEvent]()

    // Replaced Timer with DispatchWorkItem for a more GCD-native way to debounce. No RunLoop nonsense.
    private var debounceWorkItem: DispatchWorkItem?
    private var batchInterval: TimeInterval = 0.1
    private var projectSize: ProjectSize = .unknown
    private var fileCount: Int = 0

    // Filter out the cancerous folder structures no one wants to watch. Like `.git`.
    private let excludePatterns: [String]

    private let logger = Logger(
        subsystem: "com.structra.app",
        category: "FileSystemWatcher"
    )

    enum ProjectSize {
        case unknown  // Like SwiftUI state resolution
        case small  // Pre-microservices optimism
        case medium  // Developer disillusionment begins
        case large  // PTSD from `swift build` times
    }

    // Swift Dev Team said "initialize everything with safety in mind"... so here's your forced ceremony.
    init(
        paths: [String],
        excludePatterns: [String] = [
            "node_modules", ".git", "build", "dist", ".DS_Store",
        ],
        eventHandler: @escaping ([FileEvent]) -> Void
    ) {
        self.watchedPaths = paths
        self.excludePatterns = excludePatterns
        self.eventHandler = eventHandler

        eventQueue.async { [weak self] in
            self?.analyzeAndConfigureProjectSize()
        }
    }

    func cleanup() {
        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            eventStream = nil
        }
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
    }

    // The only part of this lifecycle that Swift didn’t automate or "safeguard" into total uselessness.
    deinit {
        print(
            "FileSystemWatcher deinit – being destroyed manually like a real adult."
        )
        cleanup()
    }

    private func analyzeAndConfigureProjectSize() {
        var totalFiles = 0
        let fileManager = FileManager.default

        for path in watchedPaths {
            guard
                let enumerator = fileManager.enumerator(
                    at: URL(fileURLWithPath: path),
                    includingPropertiesForKeys: [],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                )
            else { continue }

            for case let fileURL as URL in enumerator {
                if !shouldExclude(path: fileURL.path) {
                    totalFiles += 1
                }
                // A reasonable optimization to stop counting on massive projects.
                if totalFiles > 60000 { break }
            }
        }

        self.fileCount = totalFiles
        if totalFiles < 5000 {
            self.projectSize = .small
            self.batchInterval = 0.05
        } else if totalFiles < 50000 {
            self.projectSize = .medium
            self.batchInterval = 0.1
        } else {
            self.projectSize = .large
            self.batchInterval = 0.25
        }

        logger.info(
            "Project analysis complete: \(totalFiles) files. Batch interval set to \(self.batchInterval)s."
        )
    }

    private func configureForProjectSize() {
        switch projectSize {
        case .small: batchInterval = 0.05
        case .medium: batchInterval = 0.1
        case .large: batchInterval = 0.25
        case .unknown: batchInterval = 0.1
        }
    }

    // Fire up FSEvents. You’ll need all the blessings from Swift gods because nothing here is stable.
    func start() {
        guard eventStream == nil else { return }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let flags: UInt32 =
            UInt32(kFSEventStreamCreateFlagUseCFTypes)
            | UInt32(kFSEventStreamCreateFlagFileEvents)
            | UInt32(kFSEventStreamCreateFlagNoDefer)

        eventStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            {
                _,
                clientCallBackInfo,
                numEvents,
                eventPaths,
                eventFlags,
                eventIds in
                guard let clientCallBackInfo = clientCallBackInfo else {
                    return
                }
                let watcher = Unmanaged<FileSystemWatcher>.fromOpaque(
                    clientCallBackInfo
                ).takeUnretainedValue()
                let paths =
                    unsafeBitCast(eventPaths, to: CFArray.self) as! [String]
                let events = (0..<numEvents).map { i in
                    FileEvent(
                        path: paths[i],
                        flags: eventFlags[i],
                        id: eventIds[i],
                        metadata: nil
                    )
                }
                watcher.processEvents(events)
                watcher.processEvents(events)
            },
            &context,
            watchedPaths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.0,
            flags
        )

        guard let eventStream = eventStream else {
            logger.error(
                "Failed to create FSEventStream. The OS is probably having a bad day."
            )
            return
        }

        FSEventStreamSetDispatchQueue(eventStream, eventQueue)
        FSEventStreamStart(eventStream)
    }

    // Stop everything. Which in Swift means doing five things by hand because "automatic" means "magic until it breaks."
    func stop() {
        eventQueue.async {
            self.cleanup()
        }
    }

    // No 'nonisolated' needed. It's just a private method. We know what queue it runs on.
    private func shouldExclude(path: String) -> Bool {
        for pattern in excludePatterns {
            if path.contains("/\(pattern)/") || path.hasSuffix("/\(pattern)") {
                return true
            }
        }
        return false
    }

    private func processEvents(_ events: [FileEvent]) {
        let filteredEvents = events.filter {
            !self.shouldExclude(path: $0.path)
        }
        guard !filteredEvents.isEmpty else { return }

        self.eventBuffer.append(contentsOf: filteredEvents)

        // Cancel any previously scheduled flush.
        self.debounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in self?.flushEvents() }
        self.debounceWorkItem = workItem

        // [FIX] Reading `batchInterval` here is now 100% thread-safe because it's
        // only ever written on this same serial queue.
        eventQueue.asyncAfter(
            deadline: .now() + batchInterval,
            execute: workItem
        )
    }

    // Finally push the events out before ARC decides to “optimize” everything into oblivion.
    private func flushEvents() {
        guard !eventBuffer.isEmpty else { return }

        var coalesced = [String: FileEvent]()
        for event in eventBuffer {
            coalesced[event.path] = event
        }
        eventBuffer.removeAll()
        debounceWorkItem = nil

        let eventsWithMetadata = coalesced.values.map { event -> FileEvent in
            let metadata =
                event.isRemoved ? nil : self.fetchNodeMetadata(for: event.path)
            return FileEvent(
                path: event.path,
                flags: event.flags,
                id: event.id,
                metadata: metadata
            )
        }

        DispatchQueue.main.async {
            self.eventHandler(eventsWithMetadata)
        }
    }

    private func fetchNodeMetadata(for path: String) -> NodeMetadata? {
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: path)

        guard let attributes = try? fileManager.attributesOfItem(atPath: path)
        else {
            return nil
        }

        var tags: [String] = []
        if let resourceValues = try? url.resourceValues(forKeys: [.tagNamesKey]
        ),
            let tagNames = resourceValues.tagNames
        {
            tags = tagNames
        }

        let fileType = url.pathExtension
        
        print("File: \(url.path()), Size: \((attributes[.size] as? NSNumber)?.int64Value ?? -1) bytes, Tags: \(tags)")

        return NodeMetadata(
            fileSize: (attributes[.size] as? NSNumber)?.int64Value,
            creationDate: attributes[.creationDate] as? Date,
            modifiedDate: attributes[.modificationDate] as? Date,
            fileType: fileType.isEmpty ? nil : fileType,
            isReadOnly: !fileManager.isWritableFile(atPath: path),
            tags: tags
        )
    }

    func getProjectStats() -> (
        size: ProjectSize, fileCount: Int, batchInterval: TimeInterval
    ) {
        return eventQueue.sync {
            (self.projectSize, self.fileCount, self.batchInterval)
        }
    }
}
