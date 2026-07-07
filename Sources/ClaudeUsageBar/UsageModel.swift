import Foundation

@MainActor
final class UsageModel: ObservableObject {
    @Published private(set) var snapshot = UsageSnapshot.loading
    @Published private(set) var activeAccount: CswapAccount?
    @Published private(set) var accounts: [CswapAccount] = []
    @Published private(set) var switchingAccountNumber: Int?

    private let client: CswapClient
    private var refreshTask: Task<Void, Never>?
    private var switchTask: Task<Void, Never>?

    init(client: CswapClient) {
        self.client = client
        refreshTask = Task { await run() }
    }

    deinit {
        refreshTask?.cancel()
        switchTask?.cancel()
    }

    func refreshNow() {
        refreshTask?.cancel()
        refreshTask = Task { await run() }
    }

    func switchAccount(_ account: CswapAccount) {
        guard !account.active, switchingAccountNumber == nil else { return }

        switchingAccountNumber = account.number
        switchTask = Task {
            do {
                try await client.switchAccount(number: account.number)
                await refresh()
            } catch {
                snapshot = .failed(message: error.localizedDescription, updatedAt: Date())
            }

            switchingAccountNumber = nil
        }
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
