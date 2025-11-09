// Views/MenuPopoverView.swift
import SwiftUI
import AppKit

struct MenuPopoverView: View {
    @EnvironmentObject var store: NoteStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [Note] {
        store.notes
            .filter {
                query.isEmpty ||
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.preview.localizedCaseInsensitiveContains(query)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("搜索笔记…", text: $query)
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                } label: { Image(systemName: "macwindow") }
                .help("打开主窗口")
            }
            .padding([.horizontal, .top])

            if filtered.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray").font(.largeTitle)
                    Text("没有笔记").font(.headline)
                }
                .padding()
            } else {
                List(filtered) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.title).font(.headline)
                        Text(note.preview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task { @MainActor in
                            FloatingPanelManager.shared.show(note: note)
                            dismiss() // 选中后自动收起菜单栏小窗
                        }
                    }
                }
                .listStyle(.inset)
            }

            Button {
                store.showImporter.toggle()
                NSApp.activate(ignoringOtherApps: true)
                dismiss()
            } label: {
                Label("导入文档…", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .padding([.horizontal, .bottom])
        }
        .frame(width: 320, height: 420)
    }
}
