import AppKit
import SwiftUI

// SwiftUI's old minimum content frame made the window taller than the space
// above the Dock. Configure the native window once, after it is attached.
struct WindowSizingView: NSViewRepresentable {
    func makeNSView(context: Context) -> SizingHostView { SizingHostView() }
    func updateNSView(_ view: SizingHostView, context: Context) { }
}

final class SizingHostView: NSView {
    private var configured = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard !configured, let window else { return }
        configured = true
        DispatchQueue.main.async { [weak window] in
            guard let window, let screen = window.screen ?? NSScreen.main else { return }
            window.styleMask.insert(.resizable)
            let visible = screen.visibleFrame.insetBy(dx: 8, dy: 8)
            window.minSize = NSSize(width: min(680, visible.width), height: min(440, visible.height))

            var frame = window.frame
            frame.size.width = min(frame.width, visible.width)
            frame.size.height = min(frame.height, visible.height)
            frame.origin.x = min(max(frame.origin.x, visible.minX), visible.maxX - frame.width)
            frame.origin.y = min(max(frame.origin.y, visible.minY), visible.maxY - frame.height)
            if frame != window.frame { window.setFrame(frame, display: true) }
        }
    }
}
