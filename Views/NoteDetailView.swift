import SwiftUI
import PDFKit

struct NoteDetailView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: note.kind == .pdf ? "doc.richtext" : "doc.text")
                Text(note.title)
                    .font(.title3)
                    .bold()
                Spacer()
            }
            .padding(.horizontal)

            Divider()

            if note.kind == .pdf, let src = note.sourcePath {
                PDFKitView(url: src)
                    .padding(10)
            } else {
                ScrollView {
                    Text(note.preview)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
            }
        }
        .padding(.vertical)
    }
}
