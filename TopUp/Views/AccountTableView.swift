import SwiftUI

struct AccountTableView: View {
    let rows: [AccountRow]
    var onCopy: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("解析结果")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            if rows.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tablecells")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("暂无数据")
                        .font(.headline)
                    Text("在左侧粘贴包含账户信息的文本")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(rows) {
                    TableColumn("账户名称") { row in
                        copyableCell(row.accountName)
                    }
                    TableColumn("账户 ID") { row in
                        copyableCell(row.accountId)
                    }
                    TableColumn("余额") { row in
                        copyableCell(row.balance)
                    }
                    TableColumn("消耗") { row in
                        copyableCell(row.consumption)
                    }
                    TableColumn("充值金额") { row in
                        copyableCell(row.rechargeAmount)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func copyableCell(_ value: String) -> some View {
        if value.isEmpty {
            Text("—")
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    onCopy(value)
                }
                .help("点击复制")
        }
    }
}
