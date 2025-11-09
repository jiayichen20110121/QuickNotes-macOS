import SwiftUI
import AppKit

public let QUICKNOTES_FLOATING_PANEL_ID = "QuickNotesFloatingPanel"
private let kFloatingPanelFrameKey = "QuickNotes.FloatingPanel.frame"

// MARK: - 悬浮小窗内容
struct FloatingNoteView: View {
    let note: Note
    @State private var text: String = ""

    private var iconName: String {
        note.kind == .pdf ? "doc.richtext" : "note.text"
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶栏
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: iconName)
                    Text(note.title)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer()
                if let src = note.sourcePath, note.kind == .pdf {
                    Button {
                        NSWorkspace.shared.open(src)
                    } label: {
                        Label("打开原始 PDF", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.bordered)
                }
                Button {
                    NSPasteboard.general.clearContents()
                    let s = (try? String(contentsOf: note.textPath, encoding: .utf8)) ?? text
                    NSPasteboard.general.setString(s, forType: .string)
                } label: {
                    Label("复制", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)

                Button {
                    FloatingPanelManager.shared.close()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.bordered)
            }
            .padding(8)

            Divider()

            if note.kind == .pdf, let src = note.sourcePath {
                // 复用你单独文件 Views/PDFKitView.swift
                PDFKitView(url: src)
                    .padding(6)
            } else {
                ScrollView {
                    Text(text)
                        .textSelection(.enabled)
                        .font(.system(.body, design: .monospaced))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(minWidth: 260, minHeight: 180)
        .onAppear {
            text = (try? String(contentsOf: note.textPath, encoding: .utf8)) ?? ""
        }
    }
}

// MARK: - 悬浮窗管理器
@MainActor
final class FloatingPanelManager {
    static let shared = FloatingPanelManager()
    private(set) var panel: NSPanel?
    private(set) var lastNote: Note?

    // 是否可见（供 HotkeyCenter 判断）
    var isVisible: Bool { panel?.isVisible == true }

    // 显示指定笔记
    func show(note: Note) {
        lastNote = note
        ensurePanel()
        loadSavedFrameIfAny()
        setContent(with: note)
        showFront()
    }

    // 显示上一条（HotkeyCenter 用）
    func showLast(using store: NoteStore?) {
        if let n = lastNote {
            show(note: n)
            return
        }
        if let store,
           let n = store.notes.sorted(by: { $0.createdAt > $1.createdAt }).first {
            show(note: n)
            return
        }
        NSSound.beep()
    }

    // 关闭
    func close() {
        saveFrameIfAny()
        panel?.orderOut(nil)
    }

    // MARK: - 内部逻辑

    private func ensurePanel() {
        guard panel == nil else { return }

        let style: NSWindow.StyleMask = [
            .titled, .utilityWindow, .nonactivatingPanel,
            .fullSizeContentView, .resizable
        ]

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 360),
            styleMask: style,
            backing: .buffered,
            defer: false
        )

        p.title = ""
        p.titleVisibility = .hidden
        p.titlebarAppearsTransparent = true
        p.isFloatingPanel = true
        p.hidesOnDeactivate = false
        p.isReleasedWhenClosed = false
        p.isMovableByWindowBackground = true
        p.isOpaque = false
        p.hasShadow = true
        p.animationBehavior = .none

        // 关键：全屏/多桌面都在“当前 Space”弹出
        p.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]

        // 不抢焦点
        p.level = .statusBar

        // 去掉交通灯
        p.standardWindowButton(.closeButton)?.isHidden = true
        p.standardWindowButton(.miniaturizeButton)?.isHidden = true
        p.standardWindowButton(.zoomButton)?.isHidden = true

        p.minSize = NSSize(width: 260, height: 180)
        p.maxSize = NSSize(width: 2000, height: 1400)
        p.contentView?.wantsLayer = true
        p.identifier = NSUserInterfaceItemIdentifier(QUICKNOTES_FLOATING_PANEL_ID)

        // 窗口关闭时保存 frame
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: p, queue: .main
        ) { [weak self] _ in
            self?.saveFrameIfAny()
        }

        panel = p
    }

    private func setContent(with note: Note) {
        let host = NSHostingView(rootView: FloatingNoteView(note: note))
        host.translatesAutoresizingMaskIntoConstraints = false

        panel?.contentView = NSView()
        if let content = panel?.contentView {
            content.wantsLayer = true
            content.addSubview(host)
            NSLayoutConstraint.activate([
                host.leadingAnchor.constraint(equalTo: content.leadingAnchor),
                host.trailingAnchor.constraint(equalTo: content.trailingAnchor),
                host.topAnchor.constraint(equalTo: content.topAnchor),
                host.bottomAnchor.constraint(equalTo: content.bottomAnchor)
            ])
        }
    }

    private func showFront() {
        panel?.orderFrontRegardless()
    }

    private func loadSavedFrameIfAny() {
        guard let p = panel else { return }
        if let s = UserDefaults.standard.string(forKey: kFloatingPanelFrameKey) {
            let r = NSRectFromString(s)
            if r.width > 0, r.height > 0 {
                p.setFrame(r, display: true)
                return
            }
        }
        p.center()
    }

    private func saveFrameIfAny() {
        guard let p = panel else { return }
        let s = NSStringFromRect(p.frame)
        UserDefaults.standard.setValue(s, forKey: kFloatingPanelFrameKey)
    }
}
