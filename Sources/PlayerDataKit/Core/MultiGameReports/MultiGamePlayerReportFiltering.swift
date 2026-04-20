import Foundation

/// Picker 使用 `String` 表示「全部」与具体 UUID / 存档 key。
enum MultiGameReportPickerToken {
    static let all = "__ALL__"
}

/// 存档筛选下拉项：key 为 ``saveKey(gameLabel:worldDirectoryName:)``。
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
    /// 与 ``AllPlayersMultiGameReportView`` 内矩阵/热度统计中的存档 key 规则一致。
    static func saveKey(gameLabel: String, worldDirectoryName: String) -> String {
        "\(gameLabel)|\(worldDirectoryName)"
    }

    /// 与矩阵、热度、Picker 共用的「游戏实例 · 世界」展示文案。
    static func saveDisplayLabel(gameLabel: String, world: WorldPlayerRecord) -> String {
        if world.chartLabel == world.worldDirectoryName {
            "\(gameLabel) · \(world.chartLabel)"
        } else {
            "\(gameLabel) · \(world.chartLabel) (\(world.worldDirectoryName))"
        }
    }

    /// 从报表中汇总不重复的存档选项（按 label 排序）。
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

    /// 基于「全部玩家 x 全部游戏」报表结果列出玩家 UUID（按展示名排序）。
    static func sortedPlayerUUIDs(from reports: [MultiGamePlayerReport], displayName: (UUID) -> String) -> [UUID] {
        reports.map(\.playerUUID)
            .sorted { displayName($0) < displayName($1) }
    }

    /// 按所选玩家与存档筛选报表；`player == nil` 表示全部玩家，`save == nil` 表示全部存档。
    static func filter(_ input: [MultiGamePlayerReport], player: UUID?, save: String?) -> [MultiGamePlayerReport] {
        if player == nil, save == nil {
            return input
        }
        if let player, save == nil {
            return input.filter { $0.playerUUID == player }
        }

        var out: [MultiGamePlayerReport] = []
        out.reserveCapacity(input.count)

        for r in input {
            if let player, r.playerUUID != player { continue }

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

