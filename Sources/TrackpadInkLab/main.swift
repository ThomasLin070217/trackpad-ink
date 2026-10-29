import AppKit

/// A small input lab: it records touches inside this window only.
/// It does not inject events into Goodnotes or claim Apple Pencil support.
final class TrackpadCanvas: NSView {
    private var finishedStrokes: [NSBezierPath] = []
    private var currentStroke: NSBezierPath?
    private var lastLocation: NSPoint?
    private var status = "Touch the trackpad with a finger or capacitive pen"

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        allowedTouchTypes = [.indirect]
        wantsRestingTouches = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    private func location(for touch: NSTouch) -> NSPoint {
        NSPoint(
            x: touch.normalizedPosition.x * bounds.width,
            y: touch.normalizedPosition.y * bounds.height
        )
    }

    override func touchesBegan(with event: NSEvent) {
        let touches = event.touches(matching: .touching, in: self)
        guard touches.count == 1, let touch = touches.first else { return }
        let point = location(for: touch)
        let path = NSBezierPath()
        path.move(to: point)
        path.lineWidth = 2.5
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        currentStroke = path
        lastLocation = point
        status = "Touch detected — lift to finish the stroke"
        needsDisplay = true
    }

    override func touchesMoved(with event: NSEvent) {
        guard let path = currentStroke else { return }
        let touches = event.touches(matching: .touching, in: self)
        guard touches.count == 1, let touch = touches.first else { return }
        let point = location(for: touch)
        guard point != lastLocation else { return }
        path.line(to: point)
        lastLocation = point
        needsDisplay = true
    }

    override func touchesEnded(with event: NSEvent) {
        finishStroke()
    }

    override func touchesCancelled(with event: NSEvent) {
        finishStroke()
    }

    private func finishStroke() {
        if let currentStroke { finishedStrokes.append(currentStroke) }
        currentStroke = nil
        lastLocation = nil
        status = "Stroke received — input works in this lab"
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 51 { // Delete
            finishedStrokes.removeAll()
            currentStroke = nil
            status = "Canvas cleared"
            needsDisplay = true
        } else {
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        bounds.fill()

        NSColor.systemGray.withAlphaComponent(0.15).setStroke()
        let grid = NSBezierPath()
        stride(from: CGFloat(0), through: bounds.width, by: 40).forEach { x in
            grid.move(to: NSPoint(x: x, y: 0))
            grid.line(to: NSPoint(x: x, y: bounds.height))
        }
        stride(from: CGFloat(0), through: bounds.height, by: 40).forEach { y in
            grid.move(to: NSPoint(x: 0, y: y))
            grid.line(to: NSPoint(x: bounds.width, y: y))
        }
        grid.stroke()

        NSColor.systemBlue.setStroke()
        finishedStrokes.forEach { $0.stroke() }
        currentStroke?.stroke()

        let label = status as NSString
        label.draw(
            at: NSPoint(x: 12, y: 12),
            withAttributes: [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: NSColor.darkGray,
                .backgroundColor: NSColor.white
            ]
        )
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 440),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Trackpad Ink — Input Lab"
        window.center()
        let canvas = TrackpadCanvas(frame: window.contentView?.bounds ?? .zero)
        canvas.autoresizingMask = [.width, .height]
        window.contentView = canvas
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(canvas)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
