import AppKit
import SwiftUI

struct MenuBarLabel: View {
    let snapshot: UsageSnapshot

    var body: some View {
        HStack(spacing: 5) {
            Image(nsImage: MenuBarRingImage.image(percent: snapshot.percent))
                .resizable()
                .frame(width: 16, height: 16)

            Text(snapshot.remainingText)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .monospacedDigit()
        }
        .accessibilityLabel("Claude usage \(snapshot.percentText), reset in \(snapshot.remainingText)")
    }
}

struct UsagePanel: View {
    @ObservedObject var usage: UsageModel

    var body: some View {
        UsageContent(usage: usage)
        .padding(16)
    }
}

private struct UsageContent: View {
    @ObservedObject var usage: UsageModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                UsageRing(percent: usage.snapshot.percent, lineWidth: 8)
                    .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 5) {
                    Text("5h Usage")
                        .font(.headline)

                    Text(usage.snapshot.percentText)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .monospacedDigit()

                    Text("Reset in \(usage.snapshot.remainingText)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()

                    if let account = usage.activeAccount {
                        Text("#\(account.number) \(account.email)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Divider()
            status

            if !usage.accounts.isEmpty {
                Divider()
                AccountsList(accounts: usage.accounts)
            }

            HStack {
                Button("Refresh") {
                    usage.refreshNow()
                }

                Spacer()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Last updated \(usage.snapshot.updatedAt.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let error = usage.snapshot.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(usage.snapshot.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct AccountsList: View {
    let accounts: [CswapAccount]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accounts")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(accounts) { account in
                HStack(spacing: 8) {
                    Text("#\(account.number)")
                        .font(.caption)
                        .monospacedDigit()
                        .frame(width: 24, alignment: .leading)
                        .foregroundStyle(account.active ? .primary : .secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text(account.email)
                                .font(.caption)
                                .lineLimit(1)

                            if account.active {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 6, height: 6)
                            }
                        }

                        if let status = account.usageStatus {
                            Text(status)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(percentText(account.fiveHour?.percent))
                            .font(.caption)
                            .monospacedDigit()

                        Text(account.fiveHour?.countdown ?? "--")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
        }
    }

    private func percentText(_ percent: Double?) -> String {
        guard let percent else { return "--%" }
        return "\(Int((percent * 100).rounded()))%"
    }
}

struct UsageRing: View {
    let percent: Double?
    let lineWidth: Double

    private var value: Double {
        min(max(percent ?? 0, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.24), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: value)
                .stroke(
                    UsageColor.color(for: value),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

enum UsageColor {
    static func color(for value: Double) -> Color {
        switch value {
        case 0.85...:
            return .red
        case 0.65..<0.85:
            return .orange
        default:
            return .green
        }
    }

    static func nsColor(for value: Double) -> NSColor {
        switch value {
        case 0.85...:
            return .systemRed
        case 0.65..<0.85:
            return .systemOrange
        default:
            return .systemGreen
        }
    }
}

enum MenuBarRingImage {
    static func image(percent: Double?) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.isTemplate = false

        let value = min(max(percent ?? 0, 0), 1)
        let rect = NSRect(x: 3, y: 3, width: 12, height: 12)
        let lineWidth = 2.4

        image.lockFocus()

        let track = NSBezierPath(ovalIn: rect)
        track.lineWidth = lineWidth
        NSColor.labelColor.withAlphaComponent(0.34).setStroke()
        track.stroke()

        if value > 0 {
            let center = NSPoint(x: size.width / 2, y: size.height / 2)
            let radius = rect.width / 2
            let progress = NSBezierPath()
            progress.lineWidth = lineWidth
            progress.lineCapStyle = .round
            progress.appendArc(
                withCenter: center,
                radius: radius,
                startAngle: 90,
                endAngle: 90 - (360 * value),
                clockwise: true
            )
            UsageColor.nsColor(for: value).setStroke()
            progress.stroke()
        }

        image.unlockFocus()
        return image
    }
}
