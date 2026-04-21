import Foundation

enum MultiGameReportPickerToken {
    static let all = "__ALL__"
}

struct SavePickerOption: Identifiable, Hashable, Sendable {
    let key: String
    let label: String
    var id: String { key }

    init(key: String, label: String) {
        self.key = key
        self.label = label
    }
}

enum MultiGamePlayerReportFiltering {
    static func saveKey(gameLabel: String, worldDirectoryName: String) -> String {
        "\(gameLabel)|\(worldDirectoryName)"
    }

    static func saveDisplayLabel(gameLabel: String, world: WorldPlayerRecord) -> String {
        if world.chartLabel == world.worldDirectoryName {
            "\(gameLabel) · \(world.chartLabel)"
        } else {
            "\(gameLabel) · \(world.chartLabel) (\(world.worldDirectoryName))"
        }
    }

    static func makeSavePickerOptions(from reports: [MultiGamePlayerReport]) -> [SavePickerOption] {
        var dict: [String: String] = [:]
        for report in reports {
            for entry in report.entries {
                for world in entry.report.worlds {
                    let key = saveKey(gameLabel: entry.gameLabel, worldDirectoryName: world.worldDirectoryName)
                    if dict[key] == nil {
                        dict[key] = saveDisplayLabel(gameLabel: entry.gameLabel, world: world)
                    }
                }
            }
        }
        var options: [SavePickerOption] = []
        options.reserveCapacity(dict.count)
        for (key, label) in dict {
            options.append(SavePickerOption(key: key, label: label))
        }
        options.sort { $0.label < $1.label }
        return options
    }

    static func sortedPlayerUUIDs(from reports: [MultiGamePlayerReport], displayName: (String) -> String) -> [String] {
        reports.map(\.playerUUID)
            .sorted { displayName($0) < displayName($1) }
    }

    static func filterByCurrentPlayerIDs(
        _ input: [MultiGamePlayerReport],
        allowedPlayerIDs: Set<String>?
    ) -> [MultiGamePlayerReport] {
        guard let allowedPlayerIDs else {
            return input
        }
        guard allowedPlayerIDs.isEmpty == false else {
            return []
        }
        let normalizedAllowed = Set(
            allowedPlayerIDs.map { MinecraftPlayerIdentity.normalizedIdString($0) }
        )
        return input.filter { report in
            normalizedAllowed.contains(MinecraftPlayerIdentity.normalizedIdString(report.playerUUID))
        }
    }

    static func filter(_ input: [MultiGamePlayerReport], player: String?, save: String?) -> [MultiGamePlayerReport] {
        let normalizedPlayer = player.map(MinecraftPlayerIdentity.normalizedIdString)
        if player == nil, save == nil {
            return input
        }
        if let normalizedPlayer, save == nil {
            return input.filter { $0.playerUUID == normalizedPlayer }
        }

        var out: [MultiGamePlayerReport] = []
        out.reserveCapacity(input.count)

        for r in input {
            if let normalizedPlayer, r.playerUUID != normalizedPlayer { continue }

            let entries: [MultiGamePlayerReport.Entry] = r.entries.compactMap { entry in
                guard let world = entry.report.worlds.first(where: { world in
                    let key = saveKey(gameLabel: entry.gameLabel, worldDirectoryName: world.worldDirectoryName)
                    return key == save
                }) else { return nil }
                let newReport = PlayerSaveReport(playerUUID: entry.report.playerUUID, worlds: [world])
                return MultiGamePlayerReport.Entry(gameLabel: entry.gameLabel, savesRoot: entry.savesRoot, report: newReport)
            }
            guard entries.isEmpty == false else { continue }
            out.append(MultiGamePlayerReport(playerUUID: r.playerUUID, entries: entries))
        }

        return out
    }
}

