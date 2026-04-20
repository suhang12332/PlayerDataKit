import Foundation

/// 单个世界（`saves` 下的一个子文件夹）中，某 UUID 的汇总数据。
struct WorldPlayerRecord: Sendable, Identifiable {
    /// 使用世界文件夹名作为稳定标识（图表、列表）。
    var id: String { worldDirectoryName }

    let worldDirectoryName: String
    /// `level.dat` 中的 LevelName；若无法读取则为 nil。
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

    /// 图表与汇总用的展示标签。
    var chartLabel: String {
        if let displayName, !displayName.isEmpty { return displayName }
        return worldDirectoryName
    }
}

/// 某一游戏实例（一个 `saves` 根目录）下，指定 UUID 在所有单人世界中的数据。
struct PlayerSaveReport: Sendable {
    let playerUUID: UUID
    let worlds: [WorldPlayerRecord]

    init(playerUUID: UUID, worlds: [WorldPlayerRecord]) {
        self.playerUUID = playerUUID
        self.worlds = worlds
    }

    /// 各世界 `minecraft:play_time`（tick）之和；缺计为 0。
    var totalPlayTimeTicks: Int64 {
        worlds.reduce(0) { partial, w in
            partial + (w.stats?.playTimeTicks ?? 0)
        }
    }
}

/// 多个游戏（多个 `saves` 根目录）同一 UUID 的对比，用于启动器侧「多实例」报表。
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

    let playerUUID: UUID
    let entries: [Entry]

    init(playerUUID: UUID, entries: [Entry]) {
        self.playerUUID = playerUUID
        self.entries = entries
    }
}

