import SwiftUI
import AppKit

@main
struct QuickNotesApp: App {
    @StateObject private var store = NoteStore()
    @StateObject private var settings = SettingsStore()

    // 显式控制是否插入菜单栏图标；有时系统会移除，咱们可恢复
    @State private var insertMenuExtra: Bool = true

    var body: some Scene {
        // 主窗
        WindowGroup {
            ContentViewMain()
                .environmentObject(store)
                .environmentObject(settings)
                .onAppear {
                    // 全局热键
                    GlobalHotkeyCenter.shared.onSummon = { Task { @MainActor in
                        FloatingPanelManager.shared.showLast(using: store)
                    }}
                    GlobalHotkeyCenter.shared.onClose = { Task { @MainActor in
                        if FloatingPanelManager.shared.isVisible { FloatingPanelManager.shared.close() }
                    }}
                    GlobalHotkeyCenter.shared.register(summon: settings.summon, close: settings.close)

                    // 兜底的 NSEvent 监听（保持接口兼容）
                    HotkeyCenter.shared.bind(store: store, settings: settings)
                }
                // 如果 App 重新成为活跃并且图标被系统移除了，自动恢复
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    if !insertMenuExtra { insertMenuExtra = true }
                }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Import Documents…") { store.showImporter.toggle() }
                    .keyboardShortcut("i", modifiers: [.command])
            }
        }

        // 菜单栏图标（稳定版）
        MenuBarExtra("QuickNotes", systemImage: "note.text", isInserted: $insertMenuExtra) {
            // 必须传入环境对象，否则点开会崩 -> 图标消失
            MenuPopoverView()
                .environmentObject(store)
                .environmentObject(settings)
                .frame(width: 320, height: 420)
        }
        .menuBarExtraStyle(.window) // 需要可停靠的小窗口样式
    }
}

// 占位：保持老接口
final class HotkeyCenter {
    static let shared = HotkeyCenter()
    func bind(store: NoteStore, settings: SettingsStore) { /* no-op */ }
}
