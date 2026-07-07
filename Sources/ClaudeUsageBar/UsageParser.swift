import Foundation

struct UsageSnapshot: Equatable {
    var percent: Double?
    var resetAt: Date?
    var resetText: String?
    var detail: String
    var updatedAt: Date
    var errorMessage: String?

    static let loading = UsageSnapshot(
        percent: nil,
        resetAt: nil,
        resetText: nil,
        detail: "Loading usage...",
        updatedAt: Date(),
        errorMessage: nil
    )

    static func failed(message: String, updatedAt: Date) -> UsageSnapshot {
        UsageSnapshot(
            percent: nil,
            resetAt: nil,
            resetText: nil,
            detail: "Unable to fetch usage.",
            updatedAt: updatedAt,
            errorMessage: message.isEmpty ? "Unknown error." : message
        )
    }

    init(percent: Double?, resetAt: Date?, resetText: String?, detail: String, updatedAt: Date, errorMessage: String?) {
        self.percent = percent
        self.resetAt = resetAt
        self.resetText = resetText
        self.detail = detail
        self.updatedAt = updatedAt
        self.errorMessage = errorMessage
    }

    init(account: CswapAccount, updatedAt: Date) {
        let fiveHour = account.fiveHour
        self.init(
            percent: fiveHour?.percent,
            resetAt: fiveHour?.resetAt,
            resetText: fiveHour?.countdown,
            detail: "#\(account.number) \(account.email)",
            updatedAt: updatedAt,
            errorMessage: nil
        )
    }

    var percentText: String {
        guard let percent else { return "--%" }
        return "\(Int((percent * 100).rounded()))%"
    }

    var remainingText: String {
        if let resetAt {
            return TimeFormatter.shortTime(until: resetAt)
        }

        return resetText ?? "--"
    }
}

enum TimeFormatter {
    static func date(from text: String) -> Date? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: value) {
            return date
        }

        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: value)
    }

    static func shortTime(until date: Date, now: Date = Date()) -> String {
        shortDuration(seconds: max(date.timeIntervalSince(now), 0)) ?? "0m"
    }

    static func shortDuration(seconds: TimeInterval?) -> String? {
        guard let seconds else { return nil }

        let totalMinutes = max(Int(ceil(seconds / 60)), 0)
        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes % (24 * 60)) / 60
        let minutes = totalMinutes % 60

        if days > 0 {
            return hours > 0 ? "\(days)d \(hours)h" : "\(days)d"
        }

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }

        return "\(minutes)m"
    }
}
