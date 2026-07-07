import Foundation

@MainActor
final class UsageModel: ObservableObject {
    @Published private(set) var snapshot = UsageSnapshot.loading
    @Published private(set) var activeAccount: CswapAccount?
    @Published private(set) var accounts: [CswapAccount] = []

    private let client: CswapClient
    private var refreshTask: Task<Void, Never>?

    init(client: CswapClient) {
        self.client = client
        refreshTask = Task { await run() }
    }

    deinit {
        refreshTask?.cancel()
    }

    func refreshNow() {
        refreshTask?.cancel()
        refreshTask = Task { await run() }
    }

    private func run() async {
        await refresh()

        while !Task.isCancelled {
            do {
                try await Task.sleep(nanoseconds: 60_000_000_000)
            } catch {
                return
            }

            await refresh()
        }
    }

    private func refresh() async {
        do {
            let data = try await client.fetch()
            activeAccount = data.active
            accounts = data.accounts
            snapshot = UsageSnapshot(account: data.active, updatedAt: data.updatedAt)
        } catch {
            snapshot = .failed(message: error.localizedDescription, updatedAt: Date())
        }
    }
}
