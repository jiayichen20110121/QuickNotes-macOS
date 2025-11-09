import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("作者") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Image(systemName: "person.crop.circle"); Text("github:jiayichen20110121").font(.headline) }
                    Text("芒果蛋yyds").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("快捷键设置") {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("召唤浮窗").font(.headline)
                        KeyCaptureChip(hotkey: $settings.summon, allowEscape: false)
                            .frame(height: 30)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("关闭浮窗").font(.headline)
                        Toggle("使用 Esc", isOn: $settings.close.useEscape)
                        if !settings.close.useEscape {
                            KeyCaptureChip(hotkey: $settings.close, allowEscape: true)
                                .frame(height: 30)
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Button("完成") {
                    settings.persist()
                    // 重注册全局热键
                    GlobalHotkeyCenter.shared.register(summon: settings.summon, close: settings.close)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 520)
    }
}
