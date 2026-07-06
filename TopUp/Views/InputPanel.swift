import SwiftUI

struct InputPanel: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("粘贴文本")
                .font(.headline)

            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3))
                )

            Text("支持余额报告行与「名称 + ID + 充值指令」两种格式")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
