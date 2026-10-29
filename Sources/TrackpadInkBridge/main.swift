@preconcurrency import AppKit
import ApplicationServices
import OpenMultitouchSupport

/// Uses macOS's own pointer path. Raw contacts only decide when a stroke starts and ends.
/// The contact API is a private macOS framework wrapped by OpenMultitouchSupport.
@MainActor
final class Bridge: NSObject, NSApplicationDelegate {
    private let goodnotesBundleID = "com.goodnotesapp.x"
    private let syntheticTag: Int64 = 0x54494E4B // TINK
    private let manager = OMSManager.shared
    private var statusItem: NSStatusItem!
    private var toggleItem: NSMenuItem!
    private var detailItem: NSMenuItem!
    private var eventTap: CFMachPort?
    private var tapSource: CFRunLoopSource?
    private var touchTask: Task<Void, Never>?
    private var armed = false
    private var activeTouchID: Int32?
    private var waitingForClear = false
    private var strokeDown = false
    private var lastPoint: CGPoint?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "✎ Ink"
        let menu = NSMenu()
        let toggle = NSMenuItem(title: "Start Goodnotes bridge", action: #selector(toggle), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)
        let detail = NSMenuItem(title: "Off — Goodnotes only", action: nil, keyEquivalent: "")
        detail.isEnabled = false
        menu.addItem(detail)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Trackpad Ink", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        item.menu = menu
        statusItem = item
        toggleItem = toggle
        detailItem = detail

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationChanged),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func toggle() {
        if armed { stop() } else { start() }
    }

    private func start() {
        // macOS grants these asynchronously. The menu explains how to retry.
        let canListen = CGRequestListenEventAccess()
        let canPost = CGRequestPostEventAccess()
        guard canListen && canPost else {
            detailItem.title = "Grant Input Monitoring and Accessibility, then retry"
            return
        }
        guard installTap() else {
            detailItem.title = "Input Monitoring permission needed; restart after granting it"
            return
        }
        let stream = manager.touchDataStream
        touchTask = Task { [weak self] in
            for await frame in stream {
                self?.handle(frame)
            }
        }
        guard manager.startListening() else {
            touchTask?.cancel()
            touchTask = nil
            removeTap()
            detailItem.title = "Could not read trackpad contacts"
            return
        }
        armed = true
        toggleItem.title = "Stop Goodnotes bridge"
        detailItem.title = "Ready — switch to Goodnotes and touch trackpad"
    }

    private func stop() {
        endStroke()
        armed = false
        activeTouchID = nil
        waitingForClear = false
        manager.stopListening()
        touchTask?.cancel()
        touchTask = nil
        removeTap()
        toggleItem.title = "Start Goodnotes bridge"
        detailItem.title = "Off — Goodnotes only"
    }

    private func isGoodnotesFrontmost() -> Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == goodnotesBundleID
    }

    private func handle(_ frame: [OMSTouchData]) {
        guard armed else { return }
        let contacts = frame.filter { $0.state == .making || $0.state == .touching }
        if contacts.count > 1 {
            endStroke()
            activeTouchID = nil
            waitingForClear = true
            detailItem.title = "Multiple contacts — lift all fingers to reset"
            return
        }
        if frame.isEmpty || contacts.isEmpty {
            endStroke()
            activeTouchID = nil
            waitingForClear = false
            detailItem.title = isGoodnotesFrontmost() ? "Ready — next stroke" : "Ready — switch to Goodnotes"
            return
        }
        guard !waitingForClear, let contact = contacts.first else { return }
        if let activeTouchID {
            if activeTouchID != contact.id {
                endStroke()
                waitingForClear = true
            }
            return
        }
        guard isGoodnotesFrontmost() else { return }
        activeTouchID = contact.id
        guard let point = CGEvent(source: nil)?.location else { return }
        postMouse(.leftMouseDown, at: point)
        lastPoint = point
        strokeDown = true
        detailItem.title = "Drawing — lift to finish"
    }

    private func endStroke() {
        if strokeDown, let point = lastPoint {
            postMouse(.leftMouseUp, at: point)
        }
        strokeDown = false
        lastPoint = nil
    }

    private func postMouse(_ type: CGEventType, at point: CGPoint) {
        guard let event = CGEvent(mouseEventSource: nil, mouseType: type,
                                  mouseCursorPosition: point, mouseButton: .left) else { return }
        event.setIntegerValueField(.eventSourceUserData, value: syntheticTag)
        event.post(tap: .cghidEventTap)
    }

    private func installTap() -> Bool {
        let mask = [CGEventType.mouseMoved, .leftMouseDown, .leftMouseUp, .leftMouseDragged]
            .reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap,
            options: .defaultTap, eventsOfInterest: mask,
            callback: { _, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let bridge = Unmanaged<Bridge>.fromOpaque(userInfo).takeUnretainedValue()
                return MainActor.assumeIsolated { bridge.process(type: type, event: event) }
            }, userInfo: context
        ) else { return false }
        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        tapSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    private func removeTap() {
        if let source = tapSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: false) }
        tapSource = nil
        eventTap = nil
    }

    private func process(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            endStroke()
            if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        if event.getIntegerValueField(.eventSourceUserData) == syntheticTag {
            return Unmanaged.passUnretained(event)
        }
        guard armed else { return Unmanaged.passUnretained(event) }
        guard isGoodnotesFrontmost() else {
            endStroke()
            return Unmanaged.passUnretained(event)
        }
        switch type {
        case .mouseMoved:
            if strokeDown {
                lastPoint = event.location
                postMouse(.leftMouseDragged, at: event.location)
            }
            return Unmanaged.passUnretained(event)
        case .leftMouseDown, .leftMouseUp, .leftMouseDragged:
            // Drawing mode owns clicks; stop the bridge to use Goodnotes controls.
            return nil
        default:
            return Unmanaged.passUnretained(event)
        }
    }

    @objc private func applicationChanged() {
        if !isGoodnotesFrontmost() { endStroke() }
    }

    @objc private func quit() {
        stop()
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) { stop() }
}

let application = NSApplication.shared
let bridge = Bridge()
application.delegate = bridge
application.run()
