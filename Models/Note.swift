import Foundation

enum NoteKind: String, Codable {
    case text   // 只看抽取文本
    case pdf    // 以原 PDF 预览（同时有抽取文本可搜索）
}

struct Note: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var kind: NoteKind
    var textPath: URL                  // 抽取后的 .txt（用于预览摘要/搜索）
    var sourcePath: URL?               // 若为 PDF 预览，复制后的 PDF 路径
    var createdAt: Date

    var preview: String {
        (try? String(contentsOf: textPath, encoding: .utf8))?
            .prefix(280)
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .description ?? ""
    }
}
