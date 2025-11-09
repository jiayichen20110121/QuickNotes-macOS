import SwiftUI

struct KeyCaptureChip: NSViewRepresentable {
    @Binding var hotkey: Hotkey   // 仅用到修饰键 & 字母键
    let allowEscape: Bool

    func makeNSView(context: Context) -> KeyCaptureNSView {
        let v = KeyCaptureNSView()
        v.allowEscape = allowEscape
        v.onCommit = { hk in
            DispatchQueue.main.async { self.hotkey = hk }
        }
        return v
    }

    func updateNSView(_ nsView: KeyCaptureNSView, context: Context) {
        nsView.display(hotkey: hotkey)
    }
}

final class KeyCaptureNSView: NSView {
    var allowEscape: Bool = false
    var onCommit: ((Hotkey) -> Void)?

    private var isRecording = false
    private var hotkey = Hotkey()

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill(); dirtyRect.fill()

        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 6, yRadius: 6)
        (isRecording ? NSColor.controlAccentColor : NSColor.separatorColor).setStroke()
        path.lineWidth = isRecording ? 2 : 1
        path.stroke()

        let text = displayString(hotkey)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: isRecording ? NSColor.controlAccentColor : NSColor.secondaryLabelColor
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let size = str.size()
        let rect = CGRect(x: (bounds.width - size.width)/2, y: (bounds.height - size.height)/2, width: size.width, height: size.height)
        str.draw(in: rect)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        isRecording = true
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { super.keyDown(with: event); return }

        var hk = hotkey
        let flags = event.modifierFlags
        hk.useCommand = flags.contains(.command)
        hk.useControl = flags.contains(.control)
        hk.useOption  = flags.contains(.option)
        hk.useShift   = flags.contains(.shift)

        if allowEscape, event.keyCode == 53 { // ESC
            hk.useEscape = true
            isRecording = false
            onCommit?(hk)
            needsDisplay = true
            return
        }

        if let c = event.charactersIgnoringModifiers?.lowercased(), let ch = c.first, ch.isLetter {
            hk.useEscape = false
            hk.key = String(ch)
            isRecording = false
            onCommit?(hk)
            needsDisplay = true
            return
        }

        NSSound.beep() // 非法键
    }

    func display(hotkey: Hotkey) {
        self.hotkey = hotkey
        needsDisplay = true
    }

    private func displayString(_ hk: Hotkey) -> String {
        if hk.useEscape && allowEscape { return "Esc" }
        var parts: [String] = []
        if hk.useCommand { parts.append("⌘") }
        if hk.useControl { parts.append("⌃") }
        if hk.useOption  { parts.append("⌥") }
        if hk.useShift   { parts.append("⇧") }
        parts.append(hk.key.uppercased())
        return parts.joined()
    }
}
