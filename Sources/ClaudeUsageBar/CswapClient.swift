import Foundation

struct CswapClient {
    private let cswapPaths = [
        "~/.local/bin/cswap",
        "/opt/homebrew/bin/cswap",
        "/usr/local/bin/cswap"
    ]

    func fetch() async throws -> CswapData {
        async let status = runCswap(["status", "--json"])
        async let list = runCswap(["list", "--json"])

        return try CswapData.decode(status: try await status, list: try await list)
    }

    func switchAccount(number: Int) async throws {
        _ = try await runCswap(["switch", String(number), "--json"])
    }

    private func runCswap(_ arguments: [String]) async throws -> Data {
        let executable = cswapExecutable()
        let processArguments = executable.path == "/usr/bin/env" ? ["cswap"] + arguments : arguments

        return try await run(executable, arguments: processArguments)
    }

    private func cswapExecutable() -> URL {
        if let resources = Bundle.main.resourceURL {
            let bundled = resources.appendingPathComponent("cswap/cswap")
            if FileManager.default.isExecutableFile(atPath: bundled.path) {
                return bundled
            }
        }

        for path in cswapPaths {
            let expanded = NSString(string: path).expandingTildeInPath
            if FileManager.default.isExecutableFile(atPath: expanded) {
                return URL(fileURLWithPath: expanded)
            }
        }

        return URL(fileURLWithPath: "/usr/bin/env")
    }

    private func run(_ executable: URL, arguments: [String]) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = executable
            process.arguments = arguments

            let output = Pipe()
            let error = Pipe()
            process.standardOutput = output
            process.standardError = error

            let box = ContinuationBox(continuation)

            process.terminationHandler = { process in
                let data = output.fileHandleForReading.readDataToEndOfFile()
                let errorData = error.fileHandleForReading.readDataToEndOfFile()

                if process.terminationStatus == 0 {
                    box.finish(.success(data))
                } else {
                    let stdout = String(data: data, encoding: .utf8) ?? ""
                    let stderr = String(data: errorData, encoding: .utf8) ?? ""
                    box.finish(.failure(CswapError.commandFailed(stderr.isEmpty ? stdout : stderr)))
                }
            }

            do {
                try process.run()
            } catch {
                box.finish(.failure(error))
                return
            }

            Task {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                if process.isRunning {
                    process.terminate()
                    box.finish(.failure(CswapError.commandTimedOut))
                }
            }
        }
    }
}

struct CswapData: Equatable {
    var active: CswapAccount
    var accounts: [CswapAccount]
    var updatedAt: Date

    static func decode(status statusData: Data, list listData: Data, updatedAt: Date = Date()) throws -> CswapData {
        let decoder = JSONDecoder()
        let statusOutput = try decoder.decode(CswapStatusOutput.self, from: statusData)
        let listOutput = try decoder.decode(CswapListOutput.self, from: listData)

        let active = CswapAccount(statusOutput.active, isActive: true)
        let accounts = listOutput.accounts.map { CswapAccount($0, isActive: $0.number == active.number) }

        return CswapData(active: active, accounts: accounts, updatedAt: updatedAt)
    }
}

struct CswapAccount: Identifiable, Equatable {
    var id: Int { number }

    var number: Int
    var email: String
    var active: Bool
    var usageStatus: String?
    var fiveHour: CswapUsageWindow?
    var scoped: [CswapScopedWindow]

    fileprivate init(_ dto: CswapAccountDTO, isActive: Bool? = nil) {
        number = dto.number
        email = dto.email
        active = isActive ?? dto.active ?? false
        usageStatus = dto.usageStatus
        fiveHour = dto.usage?.fiveHour.map(CswapUsageWindow.init)
        scoped = (dto.usage?.scoped ?? []).compactMap(CswapScopedWindow.init)
    }
}

struct CswapScopedWindow: Identifiable, Equatable {
    var id: String { name }

    var name: String
    var window: CswapUsageWindow

    fileprivate init?(_ dto: CswapScopedWindowDTO) {
        guard let name = dto.name, !name.isEmpty else { return nil }

        self.name = name
        window = CswapUsageWindow(CswapUsageWindowDTO(pct: dto.pct, resetsAt: dto.resetsAt, countdown: dto.countdown))
    }
}

struct CswapUsageWindow: Equatable {
    var percent: Double?
    var resetAt: Date?
    var countdown: String?

    fileprivate init(_ dto: CswapUsageWindowDTO) {
        percent = dto.pct.map { min(max($0 / 100, 0), 1) }
        resetAt = dto.resetsAt.flatMap(TimeFormatter.date)
        countdown = dto.countdown
    }
}

private struct CswapListOutput: Decodable {
    var accounts: [CswapAccountDTO]
}

private struct CswapStatusOutput: Decodable {
    var active: CswapAccountDTO
}

private struct CswapAccountDTO: Decodable {
    var number: Int
    var email: String
    var active: Bool?
    var usageStatus: String?
    var usage: CswapUsageDTO?
}

private struct CswapUsageDTO: Decodable {
    var fiveHour: CswapUsageWindowDTO?
    var scoped: [CswapScopedWindowDTO]?
}

private struct CswapUsageWindowDTO: Decodable {
    var pct: Double?
    var resetsAt: String?
    var countdown: String?
}

private struct CswapScopedWindowDTO: Decodable {
    var pct: Double?
    var resetsAt: String?
    var countdown: String?
    var name: String?
}

private final class ContinuationBox: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Data, Error>?

    init(_ continuation: CheckedContinuation<Data, Error>) {
        self.continuation = continuation
    }

    func finish(_ result: Result<Data, Error>) {
        lock.lock()
        let continuation = continuation
        self.continuation = nil
        lock.unlock()

        continuation?.resume(with: result)
    }
}

enum CswapError: LocalizedError {
    case commandFailed(String)
    case commandTimedOut

    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return message.trimmingCharacters(in: .whitespacesAndNewlines)
        case .commandTimedOut:
            return "cswap command timed out."
        }
    }
}
