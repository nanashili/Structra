//
//  FileSystemWatcher.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/19/25.
//

import Cocoa
import Foundation

// Every time a file does something, this struct holds the trauma.
public struct FileEvent: Sendable {
    let path: String
    let flags: FSEventStreamEventFlags
    let id: FSEventStreamEventId

    var isCreated: Bool {
        (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated))
            != 0
    }

    var isRemoved: Bool {
        (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRemoved))
            != 0
    }

    var isModified: Bool {
        (flags
            & FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified))
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

// @MainActor – because someone at Apple had a vision of safety that now haunts every class like a ghost with OCD
@MainActor
class FileSystemWatcher {

    // Of course we need a C-style pointer ref in 2025. Thanks Swift team. Really feels modern.
    private var eventStream: FSEventStreamRef?

    // What are we watching? Our sanity dissolve? No, just file paths. Boring.
    private let watchedPaths: [String]

    // This closure is where you offload the real work. Like the Swift Concurrency Team with structured concurrency.
    private let eventHandler: ([FileEvent]) -> Void

    // DispatchQueue – because Swift Actors are still allergic to anything not 100% pure and blessed by the Pope.
    private let eventQueue = DispatchQueue(
        label: "com.filewatcher.eventQueue",
        qos: .utility
    )

    private var eventBuffer = [FileEvent]()
    private var eventTimer: Timer?

    private var batchInterval: TimeInterval = 0.1

    private var projectSize: ProjectSize = .unknown
    private var fileCount: Int = 0

    // Filter out the cancerous folder structures no one wants to watch. Like `.git`.
    private let excludePatterns: [String]

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
        self.watchedPaths = paths.map { $0.hasSuffix("/") ? $0 : $0 + "/" }
        self.excludePatterns = excludePatterns
        self.eventHandler = eventHandler

        // Let’s run analysis in a Task.detached. Because the Swift team loves giving us concurrency without actual clarity.
        Task.detached { [weak self] in
            await self?.analyzeProjectSize()
        }
    }

    func cleanup() {
        if let stream = eventStream {
            eventStream = nil
            eventQueue.sync {
                FSEventStreamStop(stream)
                FSEventStreamInvalidate(stream)
                FSEventStreamRelease(stream)
            }
        }

        // Oh look, we have to clean up our own timers. Because Swift has no idea what a lifecycle actually is.
        if let timer = eventTimer {
            timer.invalidate()
            eventTimer = nil
        }
    }

    // The only part of this lifecycle that Swift didn’t automate or "safeguard" into total uselessness.
    nonisolated deinit {
        print(
            "FileSystemWatcher deinit – destroyed manually like a real adult."
        )
    }

    private func analyzeProjectSize() async {
        var totalFiles = 0

        for path in watchedPaths {
            let fileManager = FileManager.default
            let pathURL = URL(fileURLWithPath: path)

            if let enumerator = fileManager.enumerator(
                at: pathURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) {
                var batch = [URL]()
                let batchSize = 1000

                while let fileURL = enumerator.nextObject() as? URL {
                    batch.append(fileURL)

                    if batch.count >= batchSize {
                        for url in batch {
                            let relativePath = url.path
                            var skip = false
                            if projectSize != .small {
                                for pattern in excludePatterns {
                                    if relativePath.contains("/\(pattern)/")
                                        || relativePath.hasSuffix("/\(pattern)")
                                    {
                                        skip = true
                                        break
                                    }
                                }
                            }

                            if skip { continue }
                            totalFiles += 1
                        }

                        batch.removeAll(keepingCapacity: true)
                        await Task.yield()
                        if totalFiles > 60000 { break }
                    }
                }

                for url in batch {
                    let relativePath = url.path
                    var skip = false
                    if projectSize != .small {
                        for pattern in excludePatterns {
                            if relativePath.contains("/\(pattern)/")
                                || relativePath.hasSuffix("/\(pattern)")
                            {
                                skip = true
                                break
                            }
                        }
                    }
                    if skip { continue }
                    totalFiles += 1
                    if totalFiles > 60000 { break }
                }
            }
        }

        await MainActor.run {
            fileCount = totalFiles

            // Because we’re not allowed to have dynamic enums anymore.
            if totalFiles < 5000 {
                projectSize = .small
            } else if totalFiles < 50000 {
                projectSize = .medium
            } else {
                projectSize = .large
            }

            configureForProjectSize()
            print(
                "Project analysis complete: \(totalFiles) files – SwiftPM would’ve given you 3 and a broken manifest."
            )
        }
    }

    private func configureForProjectSize() {
        switch projectSize {
        case .small:
            batchInterval = 0.05
        case .medium:
            batchInterval = 0.1
        case .large:
            batchInterval = 0.25
        case .unknown:
            batchInterval = 0.1
        }
    }

    // Fire up FSEvents. You’ll need all the blessings from Swift gods because nothing here is stable.
    func start() {
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let flagsRaw: UInt32 =
            UInt32(kFSEventStreamCreateFlagUseCFTypes)
            | UInt32(kFSEventStreamCreateFlagFileEvents)
            | UInt32(kFSEventStreamCreateFlagNoDefer)

        eventStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            {
                (
                    _,
                    clientCallBackInfo,
                    numEvents,
                    eventPaths,
                    eventFlags,
                    eventIds
                ) in
                guard let clientCallBackInfo = clientCallBackInfo else {
                    return
                }

                let watcher = Unmanaged<FileSystemWatcher>.fromOpaque(
                    clientCallBackInfo
                ).takeUnretainedValue()
                let paths =
                    unsafeBitCast(eventPaths, to: CFArray.self) as! [String]

                let events = (0..<numEvents).map {
                    i in
                    FileEvent(
                        path: paths[Int(i)],
                        flags: FSEventStreamEventFlags(eventFlags[Int(i)]),
                        id: eventIds[Int(i)]
                    )
                }

                Task { @MainActor in
                    watcher.processEvents(events)
                }
            },
            &context,
            watchedPaths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.1,
            flagsRaw
        )

        guard let eventStream = eventStream else {
            print(
                "Couldn’t create FSEventStream – maybe you need another Swift Evolution pitch."
            )
            return
        }

        FSEventStreamSetDispatchQueue(eventStream, eventQueue)
        FSEventStreamStart(eventStream)
    }

    // Stop everything. Which in Swift means doing five things by hand because "automatic" means "magic until it breaks."
    func stop() {
        guard let eventStream = eventStream else { return }

        FSEventStreamStop(eventStream)
        FSEventStreamInvalidate(eventStream)
        FSEventStreamRelease(eventStream)
        self.eventStream = nil

        eventTimer?.invalidate()
        eventTimer = nil
    }

    // Should we care about this path? Let’s overthink it like the Swift Error Handling model.
    private func shouldExclude(path: String) -> Bool {
        if projectSize == .small {
            return false
        }

        for pattern in excludePatterns {
            if path.contains("/\(pattern)/") || path.hasSuffix("/\(pattern)") {
                return true
            }
        }

        return false
    }

    // This is where the Swift team would suggest using Combine. This is where you ignore them.
    private func processEvents(_ events: [FileEvent]) {
        Task.detached { [weak self] in
            guard let self = self else { return }

            let filteredEvents = await withTaskGroup(of: (FileEvent, Bool).self)
            { group in
                for event in events {
                    group.addTask {
                        return (
                            event, await self.shouldExclude(path: event.path)
                        )
                    }
                }

                var filtered = [FileEvent]()
                for await (event, excluded) in group {
                    if !excluded {
                        filtered.append(event)
                    }
                }
                return filtered
            }

            await MainActor.run {
                self.eventBuffer.append(contentsOf: filteredEvents)

                if self.eventTimer == nil {
                    self.eventTimer = Timer.scheduledTimer(
                        withTimeInterval: self.batchInterval,
                        repeats: false
                    ) { [weak self] _ in
                        Task { @MainActor in
                            await self?.flushEvents()
                        }
                    }
                }
            }
        }
    }

    // Finally push the events out before ARC decides to “optimize” everything into oblivion.
    private func flushEvents() async {
        guard !eventBuffer.isEmpty else { return }

        var coalesced = [String: FileEvent]()
        for event in eventBuffer {
            coalesced[event.path] = event
        }

        let events = Array(coalesced.values)
        eventHandler(events)

        eventBuffer.removeAll()
        eventTimer = nil
    }

    func getProjectStats() -> (
        size: ProjectSize, fileCount: Int, batchInterval: TimeInterval
    ) {
        return (projectSize, fileCount, batchInterval)
    }
}

// Usage example
@MainActor
class FileWatcherManager {
    private var watcher: FileSystemWatcher?

    func startWatching(
        paths: [String],
        excludePatterns: [String] = ["node_modules", ".git", "build", "dist"]
    ) {
        // First clean up any existing watcher
        stopWatching()

        // Create and start a new watcher
        watcher = FileSystemWatcher(
            paths: paths,
            excludePatterns: excludePatterns
        ) { events in
            for event in events {
                if event.isCreated {
                    print("Created: \(event.path)")
                } else if event.isRemoved {
                    print("Removed: \(event.path)")
                } else if event.isModified {
                    print("Modified: \(event.path)")
                } else if event.isRenamed {
                    print("Renamed: \(event.path)")
                }
            }
        }
        watcher?.start()
    }

    func stopWatching() {
        // Call cleanup instead of stop to ensure proper resource release
        watcher?.cleanup()
        watcher = nil
    }

    // Make sure to clean up when the manager is deallocated
    // Use nonisolated deinit that doesn't call actor-isolated methods
    nonisolated deinit {
        // Create a cleanup task but don't wait for it
        // This is a best-effort cleanup for Swift 6
        Task { @MainActor [watcher] in
            // Capture watcher directly to avoid self reference
            watcher?.cleanup()
        }

        print("FileWatcherManager deinit")
    }

    func getProjectStats() -> (
        size: FileSystemWatcher.ProjectSize, fileCount: Int,
        batchInterval: TimeInterval
    )? {
        return watcher?.getProjectStats()
    }
}
