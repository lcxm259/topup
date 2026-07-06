import Foundation

enum RechargeResolver {
    static let multiplier: Decimal = 5

    static func resolve(_ account: MutableAccount) -> AccountRow {
        let rechargeAmount: String
        if let explicit = account.explicitRecharge, !explicit.isEmpty {
            rechargeAmount = explicit
        } else if let balance = decimal(from: account.balance),
                  let consumption = decimal(from: account.consumption) {
            rechargeAmount = format(consumption * multiplier - balance)
        } else {
            rechargeAmount = ""
        }

        return AccountRow(
            accountName: account.accountName,
            accountId: account.accountId,
            balance: account.balance,
            consumption: account.consumption,
            rechargeAmount: rechargeAmount
        )
    }

    static func resolve(_ accounts: [MutableAccount]) -> [AccountRow] {
        accounts.map { resolve($0) }
    }

    static func decimal(from string: String) -> Decimal? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Decimal(string: trimmed)
    }

    static func format(_ value: Decimal) -> String {
        let number = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        return formatter.string(from: number) ?? number.stringValue
    }
}
