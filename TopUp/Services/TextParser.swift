import Foundation

enum TextParser {
    private static let formatARegex: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: #"^(.+?)\((\d+)\)余额:([\d.]+)(?:\[[^\]]+\])?(?:消耗([\d.]+))?\s*$"#
        )
    }()

    private static let formatBRegex: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: #"^(.+?)\s+(\d{10,})\s*$"#
        )
    }()

    private static let rechargeRegex: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: #"(?:每个)?充值\s*(\d+(?:\.\d+)?)|(?<![值])充\s*(\d+(?:\.\d+)?)"#
        )
    }()

    private static let inlineRechargeRegex: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: #"(\d{10,}).*?(?:每个)?充值\s*(\d+(?:\.\d+)?)"#
        )
    }()

    static func parse(_ text: String) -> [AccountRow] {
        let lines = text.components(separatedBy: .newlines)
        var accounts: [String: MutableAccount] = [:]
        var order: [String] = []
        var currentBlockIds: [String] = []
        var rechargeDirectives: [(amount: String, blockIds: [String])] = []

        func upsert(_ account: MutableAccount) {
            if var existing = accounts[account.accountId] {
                existing.merge(account)
                accounts[account.accountId] = existing
            } else {
                accounts[account.accountId] = account
                order.append(account.accountId)
            }
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            if let account = parseFormatA(trimmed) {
                upsert(account)
                currentBlockIds = []
                continue
            }

            if let account = parseFormatB(trimmed) {
                upsert(account)
                currentBlockIds.append(account.accountId)
                continue
            }

            if let (accountId, amount) = parseInlineRecharge(trimmed) {
                var account = accounts[accountId] ?? MutableAccount(
                    accountName: "",
                    accountId: accountId,
                    balance: "",
                    consumption: "",
                    explicitRecharge: nil
                )
                account.explicitRecharge = amount
                upsert(account)
                currentBlockIds = []
                continue
            }

            if let amount = extractRechargeAmount(from: trimmed) {
                rechargeDirectives.append((amount: amount, blockIds: currentBlockIds))
                currentBlockIds = []
                continue
            }

            currentBlockIds = []
        }

        applyRechargeDirectives(rechargeDirectives, to: &accounts)

        return order.compactMap { accounts[$0]?.toAccountRow() }
    }

    private static func parseFormatA(_ line: String) -> MutableAccount? {
        let range = NSRange(line.startIndex..., in: line)
        guard let match = formatARegex.firstMatch(in: line, range: range) else { return nil }

        guard let nameRange = Range(match.range(at: 1), in: line),
              let idRange = Range(match.range(at: 2), in: line),
              let balanceRange = Range(match.range(at: 3), in: line) else {
            return nil
        }

        var consumption = ""
        if match.range(at: 4).location != NSNotFound,
           let consumptionRange = Range(match.range(at: 4), in: line) {
            consumption = String(line[consumptionRange])
        }

        return MutableAccount(
            accountName: String(line[nameRange]),
            accountId: String(line[idRange]),
            balance: String(line[balanceRange]),
            consumption: consumption,
            explicitRecharge: nil
        )
    }

    private static func parseFormatB(_ line: String) -> MutableAccount? {
        let range = NSRange(line.startIndex..., in: line)
        guard let match = formatBRegex.firstMatch(in: line, range: range) else { return nil }

        guard let nameRange = Range(match.range(at: 1), in: line),
              let idRange = Range(match.range(at: 2), in: line) else {
            return nil
        }

        let name = String(line[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        let accountId = String(line[idRange])

        if name.contains("余额") || name.contains("消耗") { return nil }

        return MutableAccount(
            accountName: name,
            accountId: accountId,
            balance: "",
            consumption: "",
            explicitRecharge: nil
        )
    }

    private static func parseInlineRecharge(_ line: String) -> (String, String)? {
        let range = NSRange(line.startIndex..., in: line)
        guard let match = inlineRechargeRegex.firstMatch(in: line, range: range),
              let idRange = Range(match.range(at: 1), in: line),
              let amountRange = Range(match.range(at: 2), in: line) else {
            return nil
        }
        return (String(line[idRange]), String(line[amountRange]))
    }

    private static func extractRechargeAmount(from line: String) -> String? {
        guard line.contains("充值") || line.contains("充") else { return nil }

        let range = NSRange(line.startIndex..., in: line)
        guard let match = rechargeRegex.firstMatch(in: line, range: range) else { return nil }

        if match.range(at: 1).location != NSNotFound,
           let amountRange = Range(match.range(at: 1), in: line) {
            return String(line[amountRange])
        }

        if match.range(at: 2).location != NSNotFound,
           let amountRange = Range(match.range(at: 2), in: line) {
            return String(line[amountRange])
        }

        return nil
    }

    private static func applyRechargeDirectives(
        _ directives: [(amount: String, blockIds: [String])],
        to accounts: inout [String: MutableAccount]
    ) {
        guard !directives.isEmpty else { return }

        if directives.count == 1, let directive = directives.first {
            if directive.blockIds.isEmpty {
                for id in accounts.keys {
                    accounts[id]?.explicitRecharge = directive.amount
                }
            } else {
                for id in directive.blockIds {
                    accounts[id]?.explicitRecharge = directive.amount
                }
            }
            return
        }

        for directive in directives {
            for id in directive.blockIds {
                accounts[id]?.explicitRecharge = directive.amount
            }
        }
    }
}
