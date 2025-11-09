import SwiftUI
import UniformTypeIdentifiers
import AppKit
import PDFKit

struct ContentViewMain: View {
    @EnvironmentObject var store: NoteStore
    @EnvironmentObject var settings: SettingsStore

    @State private var query = ""
    @State private var showSettings = false

    var filtered: [Note] {
        store.notes
            .filter {
                query.isEmpty ||
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.preview.localizedCaseInsensitiveContains(query)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationSplitView {
            VStack {
                HStack(spacing: 10) {
                    TextField("搜索标题或内容…", text: $query)

                    Button {
                        store.showImporter.toggle()
                    } label: {
                        Label("导入", systemImage: "square.and.arrow.down")
                    }
                    .keyboardShortcut("i", modifiers: [.command])

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .help("设置")
                }
                .padding(.horizontal)

                List(selection: $store.selectedNoteID) {
                    ForEach(filtered) { note in
                        NoteRowView(note: note)
                            .tag(note.id)
                            .onTapGesture { store.selectedNoteID = note.id }
                    }
                }
                .listStyle(.inset)
            }
            .navigationTitle("QuickNotes")
        } detail: {
            if let id = store.selectedNoteID,
               let note = store.notes.first(where: { $0.id == id }) {
                NoteDetailView(note: note)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "note.text").font(.largeTitle)
                    Text("选择左侧笔记以预览").font(.headline)
                }
                .foregroundStyle(.secondary)
            }
        }
        // 仅保留统一导入入口：导入到 NoteStore 处理（无选择弹窗）
        .fileImporter(
            isPresented: $store.showImporter,
            allowedContentTypes: [.pdf, .plainText, .rtf, .rtfd, .html, .commaSeparatedText],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task { await store.importFromURLs(urls) }
            case .failure(let err):
                print("导入失败：\(err.localizedDescription)")
            }
        }
        // 设置窗口
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(settings)
        }
        .frame(minWidth: 800, minHeight: 560)
    }
}
