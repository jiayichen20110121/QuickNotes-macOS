import SwiftUI
import PDFKit

/// 单条笔记的列表行
struct NoteRowView: View {
    @EnvironmentObject var store: NoteStore
    let note: Note

    var body: some View {
        HStack(alignment: .top, spacing: 10) {

            // 图标（PDF/TXT）
            Image(systemName: note.kind == .pdf ? "doc.richtext" : "doc.text")
                .font(.title3)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.headline)

                Text(note.preview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())     // 让整行都能响应点击
        .contextMenu {                 // ✅ 右键菜单（恢复）
            
            Button("打开原文件") {
                openOriginal()
            }

            Button("在 Finder 中显示") {
                revealInFinder()
            }

            Divider()

            Button(role: .destructive) {
                Task { @MainActor in
                    store.delete(note)
                }
            } label: {
                Text("删除笔记")
            }
        }
    }

    // MARK: - 打开原文件
    private func openOriginal() {
        if let url = note.sourcePath,
           FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.activateFileViewerSelecting([note.textPath])
        }
    }

    // MARK: - Finder 显示
    private func revealInFinder() {
        if let url = note.sourcePath,
           FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            NSWorkspace.shared.activateFileViewerSelecting([note.textPath])
        }
    }
}
