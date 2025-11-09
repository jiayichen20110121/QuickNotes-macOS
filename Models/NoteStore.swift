import SwiftUI
import UniformTypeIdentifiers
import PDFKit

@MainActor
final class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    @Published var showImporter = false
    @Published var selectedNoteID: UUID?

    private let fm = FileManager.default
    private let metaFileName = "notes.json"

    var notesDir: URL {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("QuickNotesNotes", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    init() { load() }

    // MARK: - 导入入口（不再弹任何选择框）
    func importFromURLs(_ urls: [URL]) async {
        for url in urls {
            let ext = url.pathExtension.lowercased()
            if ext == "pdf" {
                await importPDF(url)
            } else {
                await importPlainFile(url)
            }
        }
        save()
    }

    // 仅复制原 PDF，生成占位 txt，类型设为 .pdf
    private func importPDF(_ url: URL) async {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            let base = sanitizedFileName(url.deletingPathExtension().lastPathComponent)
            let pdfURL = notesDir.appendingPathComponent("\(base)-\(UUID().uuidString.prefix(6)).pdf")
            try? fm.removeItem(at: pdfURL)
            try fm.copyItem(at: url, to: pdfURL)

            // 占位 txt（不做任何识别/抽取）
            let txtURL = notesDir.appendingPathComponent("\(base)-\(UUID().uuidString.prefix(6)).txt")
            try "".write(to: txtURL, atomically: true, encoding: .utf8)

            let note = Note(
                id: UUID(),
                title: base,
                kind: .pdf,
                textPath: txtURL,
                sourcePath: pdfURL,
                createdAt: Date()
            )
            notes.append(note)
        } catch {
            print("导入 PDF 失败：\(error.localizedDescription)")
        }
    }

    // 非 PDF：直接读为文本（这是原生文本，不是“识别”）
    private func importPlainFile(_ url: URL) async {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            let base = sanitizedFileName(url.deletingPathExtension().lastPathComponent)
            let text = try readText(from: url)      // 不支持的类型会抛错
            let txtURL = notesDir.appendingPathComponent("\(base)-\(UUID().uuidString.prefix(6)).txt")
            try text.write(to: txtURL, atomically: true, encoding: .utf8)

            let note = Note(
                id: UUID(),
                title: base,
                kind: .text,
                textPath: txtURL,
                sourcePath: nil,
                createdAt: Date()
            )
            notes.append(note)
        } catch {
            print("导入失败：\(url.lastPathComponent) – \(error.localizedDescription)")
        }
    }

    func delete(_ note: Note) {
        if fm.fileExists(atPath: note.textPath.path) { try? fm.removeItem(at: note.textPath) }
        if let src = note.sourcePath, fm.fileExists(atPath: src.path) { try? fm.removeItem(at: src) }
        notes.removeAll { $0.id == note.id }
        save()
    }

    // MARK: - 持久化
    private func metaURL() -> URL { notesDir.appendingPathComponent(metaFileName) }

    private func save() {
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: metaURL(), options: .atomic)
        } catch { print("保存索引失败：\(error)") }
    }

    private func load() {
        let url = metaURL()
        guard fm.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            notes = try JSONDecoder().decode([Note].self, from: data)
        } catch { print("读取索引失败：\(error)") }
    }

    // MARK: - 读取原生文本（不做 PDF 抽取/识别）
    private func sanitizedFileName(_ s: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return s.components(separatedBy: invalid).joined().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func readText(from url: URL) throws -> String {
        let ext = url.pathExtension.lowercased()

        // 纯文本
        if ["txt", "md", "csv", "log"].contains(ext) {
            return try String(contentsOf: url, encoding: .utf8)
        }

        // RTF/HTML -> 仅做系统级反序列化，不做“识别”
        if ["rtf", "rtfd", "html", "htm"].contains(ext) {
            let data = try Data(contentsOf: url)
            if let attr = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: (ext == "rtf" || ext == "rtfd") ? NSAttributedString.DocumentType.rtf : .html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            ) {
                return attr.string
            } else {
                throw NSError(domain: "QuickNotes.Read", code: -2,
                              userInfo: [NSLocalizedDescriptionKey: "无法读取该文本格式"])
            }
        }

        // 其它类型当作不支持
        throw NSError(domain: "QuickNotes.Read", code: -3,
                      userInfo: [NSLocalizedDescriptionKey: "不支持的文件类型：\(ext.uppercased())"])
    }

    // 外部：浮窗快捷入口（保留）
    func showFloating(note: Note) { FloatingPanelManager.shared.show(note: note) }
}
