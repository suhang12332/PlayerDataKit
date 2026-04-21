import Foundation

/// 单个世界中的玩家数据。
struct WorldPlayerRecord: Sendable, Identifiable {
    /// 以世界目录名为稳定标识。
    var id: String { worldDirectoryName }

    let worldDirectoryName: String
    /// 来自 `level.dat` 的 LevelName。
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

    /// 图表展示名。
    var chartLabel: String {
        if let displayName, !displayName.isEmpty { return displayName }
        return worldDirectoryName
    }
}

/// 单个游戏实例下的玩家汇总。
struct PlayerSaveReport: Sendable {
    let playerUUID: String
    let worlds: [WorldPlayerRecord]

    init(playerUUID: String, worlds: [WorldPlayerRecord]) {
        self.playerUUID = MinecraftPlayerIdentity.normalizedIdString(playerUUID)
        self.worlds = worlds
    }

    /// 各世界 `play_time` tick 总和。
    var totalPlayTimeTicks: Int64 {
        worlds.reduce(0) { partial, w in
            partial + (w.stats?.playTimeTicks ?? 0)
        }
    }
}

/// 同一玩家在多个游戏实例下的对比报表。
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

