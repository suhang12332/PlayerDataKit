import Foundation

struct WorldPlayerRecord: Sendable, Identifiable {
    var id: String { worldDirectoryName }

    let worldDirectoryName: String
    let displayName: String?
    let stats: MinecraftStatsSnapshot?
    let advancements: MinecraftAdvancementsSnapshot?

    init(
        worldDirectoryName: String,
        displayName: String?,
        stats: MinecraftStatsSnapshot?,
        advancements: MinecraftAdvancementsSnapshot?
    ) {
        self.worldDirectoryName = worldDirectoryName
        self.displayName = displayName
        self.stats = stats
        self.advancements = advancements
    }

    var chartLabel: String {
        if let displayName, !displayName.isEmpty { return displayName }
        return worldDirectoryName
    }
}

struct PlayerSaveReport: Sendable {
    let playerUUID: String
    let worlds: [WorldPlayerRecord]

    init(playerUUID: String, worlds: [WorldPlayerRecord]) {
        self.playerUUID = MinecraftPlayerIdentity.normalizedIdString(playerUUID)
        self.worlds = worlds
    }

    var totalPlayTimeTicks: Int64 {
        worlds.reduce(0) { partial, w in
            partial + (w.stats?.playTimeTicks ?? 0)
        }
    }
}

struct MultiGamePlayerReport: Sendable {
    struct Entry: Sendable, Identifiable {
        var id: String { savesRoot.path }
        let gameLabel: String
        let savesRoot: URL
        let report: PlayerSaveReport

        init(gameLabel: String, savesRoot: URL, report: PlayerSaveReport) {
            self.gameLabel = gameLabel
            self.savesRoot = savesRoot
            self.report = report
        }
    }

    let playerUUID: String
    let entries: [Entry]

    init(playerUUID: String, entries: [Entry]) {
        self.playerUUID = MinecraftPlayerIdentity.normalizedIdString(playerUUID)
        self.entries = entries
    }
}

