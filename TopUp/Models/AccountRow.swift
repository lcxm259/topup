import Foundation

struct AccountRow: Identifiable, Equatable {
    let id: UUID
    var accountName: String
    var accountId: String
    var balance: String
    var consumption: String
    var rechargeAmount: String

    init(
        id: UUID = UUID(),
        accountName: String = "",
        accountId: String = "",
        balance: String = "",
        consumption: String = "",
        rechargeAmount: String = ""
    ) {
        self.id = id
        self.accountName = accountName
        self.accountId = accountId
        self.balance = balance
        self.consumption = consumption
        self.rechargeAmount = rechargeAmount
    }
}

struct MutableAccount {
    var accountName: String
    var accountId: String
    var balance: String
    var consumption: String
    var explicitRecharge: String?

    mutating func merge(_ other: MutableAccount) {
        if accountName.isEmpty { accountName = other.accountName }
        if balance.isEmpty { balance = other.balance }
        if consumption.isEmpty { consumption = other.consumption }
        if explicitRecharge == nil { explicitRecharge = other.explicitRecharge }
    }

    func toAccountRow() -> AccountRow {
        RechargeResolver.resolve(MutableAccount(
            accountName: accountName,
            accountId: accountId,
            balance: balance,
            consumption: consumption,
            explicitRecharge: explicitRecharge
        ))
    }
}
