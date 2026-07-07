import SwiftUI

@main
struct ClaudeUsageBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var usage = UsageModel(client: CswapClient())

    var body: some Scene {
        MenuBarExtra {
            UsagePanel(usage: usage)
                .frame(width: 380)
        } label: {
            MenuBarLabel(snapshot: usage.snapshot)
        }
        .menuBarExtraStyle(.window)
    }
}
