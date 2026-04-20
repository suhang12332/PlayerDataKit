import Foundation

/// 用于构建多实例统计报表的源：展示名 + 档案根目录（其下应有 `saves` 子目录）。
public struct GameInstanceReportSource: Sendable, Equatable {
    let displayName: String
    let profileRoot: URL

    public init(displayName: String, profileRoot: URL) {
        self.displayName = displayName
        self.profileRoot = profileRoot
    }
}

/// 从多个游戏档案目录生成 ``AllPlayersMultiGameStatsController/configureAndLoad(entries:)`` 所需的条目。
public enum GameInstanceReportEntries {
    /// 构建 `(label, savesRoot)`，仅保留磁盘上存在 `saves` 子目录的项。
    ///
    /// - Parameters:
    ///   - sources: 与启动器游戏列表顺序一致；`displayName` 重复的项按出现顺序标为 `"名称 #1"`、`"名称 #2"`，唯一名称不追加序号。
    ///   - savesDirectoryName: 相对于 `profileRoot` 的存档目录名，默认 `saves`（与 Minecraft Java 一致）。
    ///
    /// 序号在**全部** `sources` 上递增；若某项因缺少 `saves` 被跳过，仍占用该名称下的序号，与启动器原行为一致。
    public static func build(
        sources: [GameInstanceReportSource],
        savesDirectoryName: String = "saves"
    ) -> [(label: String, savesRoot: URL)] {
        let fm = FileManager.default
        var nameOccurrences: [String: Int] = [:]
        nameOccurrences.reserveCapacity(sources.count)
        for source in sources {
            nameOccurrences[source.displayName, default: 0] += 1
        }
        var nameCounter: [String: Int] = [:]
        nameCounter.reserveCapacity(nameOccurrences.count)
        return sources.compactMap { source in
            let currentIndex = (nameCounter[source.displayName] ?? 0) + 1
            nameCounter[source.displayName] = currentIndex

            let savesRoot = source.profileRoot.appendingPathComponent(savesDirectoryName, isDirectory: true)
            guard fm.fileExists(atPath: savesRoot.path) else { return nil }

            let hasDuplicateName = (nameOccurrences[source.displayName] ?? 0) > 1
            let label = hasDuplicateName ? "\(source.displayName) #\(currentIndex)" : source.displayName
            return (label: label, savesRoot: savesRoot)
        }
    }
}

