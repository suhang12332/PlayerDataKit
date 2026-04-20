import Foundation

struct MinecraftAdvancementsSnapshot: Sendable {
    let completedCount: Int
    let totalCount: Int
}

enum MinecraftAdvancementsParser {
    static func parse(jsonData: Data) throws -> MinecraftAdvancementsSnapshot {
        let obj = try JSONSerialization.jsonObject(with: jsonData, options: [])
        guard let root = obj as? [String: Any] else {
            return MinecraftAdvancementsSnapshot(completedCount: 0, totalCount: 0)
        }

        var total = 0
        var done = 0
        for (key, value) in root {
            if key == "DataVersion" { continue }
            guard let adv = value as? [String: Any] else { continue }
            total += 1
            if (adv["done"] as? Bool) == true {
                done += 1
            }
        }
        return MinecraftAdvancementsSnapshot(completedCount: done, totalCount: total)
    }
}

