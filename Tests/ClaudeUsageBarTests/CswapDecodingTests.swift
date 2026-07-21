import XCTest
@testable import ClaudeUsageBar

final class CswapDecodingTests: XCTestCase {
    private let statusJSON = Data("""
    {
        "schemaVersion": 1,
        "active": {
            "number": 2,
            "email": "two@example.com",
            "usageStatus": "ok",
            "usage": {
                "fiveHour": {
                    "pct": 18.0,
                    "resetsAt": "2026-07-21T10:39:59.530928+00:00",
                    "countdown": "2h 4m",
                    "clock": "14:39"
                },
                "sevenDay": {
                    "pct": 9.0,
                    "resetsAt": "2026-07-25T18:59:59.530954+00:00",
                    "countdown": "4d 10h",
                    "clock": "Jul 25 22:59"
                },
                "scoped": [
                    {
                        "pct": 6.0,
                        "resetsAt": "2026-07-25T18:59:59.531270+00:00",
                        "countdown": "4d 10h",
                        "clock": "Jul 25 22:59",
                        "name": "Fable"
                    }
                ]
            }
        },
        "totalManagedAccounts": 2
    }
    """.utf8)

    private let listJSON = Data("""
    {
        "schemaVersion": 1,
        "activeAccountNumber": 2,
        "accounts": [
            {
                "number": 1,
                "email": "one@example.com",
                "active": false,
                "usageStatus": "rate_limited"
            },
            {
                "number": 2,
                "email": "two@example.com",
                "active": true,
                "usageStatus": "ok",
                "usage": {
                    "fiveHour": {
                        "pct": 18.0,
                        "resetsAt": "2026-07-21T10:39:59.530928+00:00",
                        "countdown": "2h 4m"
                    },
                    "scoped": [
                        {
                            "pct": 100.0,
                            "resetsAt": "2026-07-25T18:59:59.531270+00:00",
                            "countdown": "4d 10h",
                            "name": "Fable"
                        }
                    ]
                }
            }
        ]
    }
    """.utf8)

    func testDecodesScopedFableUsageForActiveAccount() throws {
        let data = try CswapData.decode(status: statusJSON, list: listJSON)

        XCTAssertEqual(data.active.scoped.count, 1)

        let fable = try XCTUnwrap(data.active.scoped.first)
        XCTAssertEqual(fable.name, "Fable")
        XCTAssertEqual(try XCTUnwrap(fable.window.percent), 0.06, accuracy: 0.0001)
        XCTAssertEqual(fable.window.countdown, "4d 10h")
        XCTAssertNotNil(fable.window.resetAt)
    }

    func testDecodesScopedUsagePerAccountInList() throws {
        let data = try CswapData.decode(status: statusJSON, list: listJSON)

        XCTAssertEqual(data.accounts.count, 2)

        let first = data.accounts[0]
        XCTAssertTrue(first.scoped.isEmpty)
        XCTAssertNil(first.fiveHour)
        XCTAssertFalse(first.active)

        let second = data.accounts[1]
        XCTAssertTrue(second.active)
        XCTAssertEqual(second.scoped.first?.name, "Fable")
        XCTAssertEqual(try XCTUnwrap(second.scoped.first?.window.percent), 1.0, accuracy: 0.0001)
    }
}
