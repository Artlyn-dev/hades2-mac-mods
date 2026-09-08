import AppKit
import Foundation

struct Feature: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let symbol: String

    static let catalog: [Feature] = [
        Feature(
            id: "dream_length",
            title: "Dream Dive: 8 zones",
            description: "8 biomes, max Vow of Rivals covers 5–8, scaling past zone 4, ally rarity/damage, and a Pool of Purging after each boss.",
            symbol: "moon.stars.fill"
        ),
        Feature(
            id: "dream_rewards",
            title: "Dream Dive: hammers & gods",
            description: "3rd hammer after 4 zones, 4th later, and a 5th god from zone 5.",
            symbol: "hammer.fill"
        ),
        Feature(
            id: "dream_shop_pacing",
            title: "Dream Dive: shop pacing",
            description: "Shop and Nemesis first/second half follow half the dive, not a hard 2-zone split.",
            symbol: "cart.fill"
        ),
        Feature(
            id: "dream_scaling",
            title: "Dream Dive: 5–8 scaling",
            description: "Zones 5–8 keep scaling past biome 4, including ally rarity/damage (also on with 8 zones).",
            symbol: "chart.line.uptrend.xyaxis"
        ),
        Feature(
            id: "night_bloom_scale",
            title: "Night Bloom: biome damage",
            description: "Raised servants keep the hex multipliers, plus ally biome damage (1.22 per zone). Independent of Artemis/Icarus/Heracles.",
            symbol: "moon.fill"
        ),
        Feature(
            id: "scorch_cap",
            title: "Scorch cap",
            description: "Raises Scorch (Burn) stack cap from 999 to 99,999.",
            symbol: "flame.fill"
        ),
        Feature(
            id: "support_fire",
            title: "Support Fire",
            description: "Arrows keep up with attack speed (cap 30) and Poms actually raise damage.",
            symbol: "arrow.forward.circle.fill"
        ),
        Feature(
            id: "support_fire_scale",
            title: "Support Fire: biome damage",
            description: "Arrow damage +10% per biome after the first (biome 8 = +70%).",
            symbol: "arrow.up.right"
        ),
        Feature(
            id: "pommable_boons",
            title: "Pommable boons",
            description: "Pom Killing Stroke, Easy Shot, Winner's Circle, and Success Rate.",
            symbol: "leaf.fill"
        ),
        Feature(
            id: "reckless_abandon",
            title: "Reckless Abandon",
            description: "Even 33% rolls on 5/55/555, plus +111 per biome you picked it in.",
            symbol: "die.face.5.fill"
        ),
        Feature(
            id: "discordant_bell",
            title: "Discordant Bell",
            description: "Eris keepsake grows +5% damage dealt and taken after each encounter.",
            symbol: "bell.fill"
        ),
        Feature(
            id: "damage_meter",
            title: "Damage meter",
            description: "In-combat breakdown of damage by source with % of the room (Jowday-style). Independent of Dream Dive toggles.",
            symbol: "chart.bar.fill"
        ),
    ]
}

struct ToolStatus: Decodable {
    var ok: Bool
    var game: Bool
    var backup: Bool
    var hadesRunning: Bool
    var gamePath: String
    var backupPath: String
    var error: String?

    enum CodingKeys: String, CodingKey {
        case ok, game, backup, error
        case hadesRunning = "hades_running"
        case gamePath = "game_path"
        case backupPath = "backup_path"
    }
}

struct ToolResult: Decodable {
    var ok: Bool
    var enabled: [String]?
    var log: [String]?
    var error: String?
    var hadesRunning: Bool?

    enum CodingKeys: String, CodingKey {
        case ok, enabled, log, error
        case hadesRunning = "hades_running"
    }
}

struct EnabledFile: Codable {
    var enabled: [String]
}

enum PatchEngine {
    static let steamLaunchURL = URL(string: "steam://rungameid/1145350")!

    static var supportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Hades2LocalMods", isDirectory: true)
    }

    static var enabledURL: URL {
        supportDirectory.appendingPathComponent("enabled.json")
    }

    static func repoRoot() throws -> URL {
        if let env = ProcessInfo.processInfo.environment["HADES2_MOD_ROOT"], !env.isEmpty {
            let url = URL(fileURLWithPath: env, isDirectory: true)
            if FileManager.default.fileExists(atPath: url.appendingPathComponent("tools/apply-mod.py").path) {
                return url
            }
        }
        var starts: [URL] = []
        if let exe = Bundle.main.executableURL { starts.append(exe) }
        starts.append(Bundle.main.bundleURL)
        starts.append(URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true))
        for start in starts {
            var current = start.standardizedFileURL
            for _ in 0..<14 {
                let marker = current.appendingPathComponent("tools/apply-mod.py")
                if FileManager.default.fileExists(atPath: marker.path) {
                    return current
                }
                current.deleteLastPathComponent()
            }
        }
        throw EngineError("Could not find tools/apply-mod.py. Keep the app next to the hades_2 repo.")
    }

    static func loadEnabled() -> Set<String> {
        guard let data = try? Data(contentsOf: enabledURL) else { return [] }
        let decoded = try? JSONDecoder().decode(EnabledFile.self, from: data)
        return Set(decoded?.enabled ?? [])
    }

    static func saveEnabled(_ ids: Set<String>) throws {
        try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
        let payload = EnabledFile(enabled: Feature.catalog.map(\.id).filter { ids.contains($0) })
        let data = try JSONEncoder().encode(payload)
        try data.write(to: enabledURL, options: .atomic)
    }

    static func status() throws -> ToolStatus {
        try decode(runPython(["--status", "--json"]))
    }

    static func apply(ids: Set<String>) throws -> ToolResult {
        try saveEnabled(ids)
        let ordered = Feature.catalog.map(\.id).filter { ids.contains($0) }
        return try decode(runPython(["--enable", ordered.joined(separator: ","), "--json"]))
    }

    static func restore() throws -> ToolResult {
        let root = try repoRoot()
        let script = root.appendingPathComponent("tools/restore-vanilla.sh")
        let output = try runProcess(
            executable: "/bin/bash",
            arguments: [script.path]
        )
        if output.exitCode != 0 {
            throw EngineError(output.combined.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                ?? "Reset to vanilla failed.")
        }
        try saveEnabled([])
        return ToolResult(
            ok: true,
            enabled: [],
            log: [output.combined.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                ?? "Restored Scripts and Game from vanilla-backup."],
            error: nil,
            hadesRunning: nil
        )
    }

    static func launchGame() {
        NSWorkspace.shared.open(steamLaunchURL)
    }

    private static func runPython(_ arguments: [String]) throws -> Data {
        let script = try repoRoot().appendingPathComponent("tools/apply-mod.py")
        let output = try runProcess(
            executable: "/usr/bin/python3",
            arguments: [script.path] + arguments
        )
        let data = Data(output.stdout.utf8)
        if output.exitCode != 0 {
            if let parsed = try? JSONDecoder().decode(ToolResult.self, from: data), let error = parsed.error {
                throw EngineError(error)
            }
            throw EngineError(output.combined.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                ?? "python3 apply-mod.py failed (\(output.exitCode)).")
        }
        return data
    }

    private static func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw EngineError(text.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                ?? "Could not parse tool output.")
        }
    }

    private static func runProcess(executable: String, arguments: [String]) throws -> ProcessOutput {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        try process.run()
        process.waitUntilExit()
        let out = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let err = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return ProcessOutput(exitCode: Int(process.terminationStatus), stdout: out, stderr: err)
    }
}

struct EngineError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

private struct ProcessOutput {
    let exitCode: Int
    let stdout: String
    let stderr: String
    var combined: String {
        [stdout, stderr].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.joined(separator: "\n")
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
