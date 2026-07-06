import XCTest
@testable import TopUp

final class TextParserTests: XCTestCase {
    func testFormatAFullSample() {
        let text = """
        账户余额不足2.5天消耗

        投放平台: adwords

        账户总数: 96

        AT_ZT_MOQ_0422_USD_1(7379891084)余额:1172.90[USD]消耗614.70

        Madhouse_ZT_FTE_0310_USD_1(7214932584)余额:148.79[USD]消耗81.35

        AT_ZT_MGM_0326_USD_1(4181357997)余额:1103.90[USD]消耗551.37

        CO_ZT_SST_1030_USD_1(9236452249)余额:3073.01[USD]消耗1333.87
        """

        let rows = TextParser.parse(text)
        XCTAssertEqual(rows.count, 4)

        let mgm = rows.first { $0.accountId == "4181357997" }
        XCTAssertEqual(mgm?.accountName, "AT_ZT_MGM_0326_USD_1")
        XCTAssertEqual(mgm?.balance, "1103.90")
        XCTAssertEqual(mgm?.consumption, "551.37")
        XCTAssertEqual(mgm?.rechargeAmount, "1652.95")
    }

    func testFormatBWithGlobalRecharge() {
        let text = """
        TT-ZS-0322-AD-05 7620118251488673793
        TT-ZS-0322-AE-01 7620118304094732304
        TT-ZS-0322-AE-02 7620118310236536849
        辛苦上面这些账户每个充值500美金
        """

        let rows = TextParser.parse(text)
        XCTAssertEqual(rows.count, 3)
        XCTAssertTrue(rows.allSatisfy { $0.rechargeAmount == "500" })
        XCTAssertEqual(rows[0].accountName, "TT-ZS-0322-AD-05")
        XCTAssertEqual(rows[0].accountId, "7620118251488673793")
    }

    func testIgnoresHeaderLines() {
        let text = "账户总数: 96\n投放平台: adwords"
        XCTAssertTrue(TextParser.parse(text).isEmpty)
    }

    func testEmptyInput() {
        XCTAssertTrue(TextParser.parse("").isEmpty)
    }

    func testConsumptionOnlyDoesNotCalculateRechargeWithoutBalance() {
        let text = "AT_ZT_MGM_0326_USD_1(4181357997)余额:1103.90[USD]"
        let row = TextParser.parse(text).first
        XCTAssertEqual(row?.balance, "1103.90")
        XCTAssertEqual(row?.consumption, "")
        XCTAssertEqual(row?.rechargeAmount, "")
    }

    func testRechargeFormula() {
        let account = MutableAccount(
            accountName: "Test",
            accountId: "1",
            balance: "1103.90",
            consumption: "551.37",
            explicitRecharge: nil
        )
        let row = RechargeResolver.resolve(account)
        XCTAssertEqual(row.rechargeAmount, "1652.95")
    }

    func testExplicitRechargeOverridesFormula() {
        let account = MutableAccount(
            accountName: "Test",
            accountId: "1",
            balance: "1103.90",
            consumption: "551.37",
            explicitRecharge: "500"
        )
        let row = RechargeResolver.resolve(account)
        XCTAssertEqual(row.rechargeAmount, "500")
    }
}
