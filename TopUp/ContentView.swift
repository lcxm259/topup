import SwiftUI

struct ContentView: View {
    @State private var inputText = ""
    @State private var rows: [AccountRow] = []
    @State private var statusMessage = "点击单元格复制"
    @State private var parseTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                InputPanel(text: $inputText)
                    .frame(minWidth: 280)

                AccountTableView(rows: rows) { value in
                    ClipboardService.copy(value)
                    statusMessage = "已复制: \(value)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if statusMessage == "已复制: \(value)" {
                            statusMessage = "点击单元格复制"
                        }
                    }
                }
                .frame(minWidth: 420)
            }

            Divider()

            HStack {
                Text("已解析 \(rows.count) 条账户")
                Spacer()
                Text(statusMessage)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .navigationTitle("账户解析")
        .onChange(of: inputText) { newValue in
            scheduleParse(newValue)
        }
    }

    private func scheduleParse(_ text: String) {
        parseTask?.cancel()
        parseTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            let parsed = TextParser.parse(text)
            await MainActor.run {
                rows = parsed
            }
        }
    }
}
