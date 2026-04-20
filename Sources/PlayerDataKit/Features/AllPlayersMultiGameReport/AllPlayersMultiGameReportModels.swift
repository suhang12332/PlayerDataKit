import Foundation

// MARK: - 格式化

enum Formatting {
    static func hours(fromTicks ticks: Int64?) -> Double {
        guard let t = ticks, t > 0 else { return 0 }
        return Double(t) / 20 / 3600
    }

    static func shortDurationDescription(fromTicks: Int64?) -> String {
        guard let t = fromTicks, t > 0 else {
            return PDKL10n.string("allPlayers.placeholder.empty")
        }
        let sec = Double(t) / 20
        if sec < 60 {
            return PDKL10n.format("allPlayers.format.duration.seconds", sec)
        }
        let min = sec / 60
        if min < 60 {
            return PDKL10n.format("allPlayers.format.duration.minutes", min)
        }
        let h = min / 60
        if h < 48 {
            return PDKL10n.format("allPlayers.format.duration.hours", h)
        }
        let d = h / 24
        return PDKL10n.format("allPlayers.format.duration.days", d)
    }

    static func kilometers(fromCm: Int64?) -> Double {
        guard let cm = fromCm else { return 0 }
        return Double(cm) / 100_000
    }
}

struct GamePlayerPlayRow: Identifiable {
    let gameLabel: String
    let playerUUID: UUID
    let playHours: Double
    /// 图例与堆叠系列标签（已处理重名）。
    let playerLabel: String
    var id: String { "\(gameLabel)|\(playerUUID.uuidString)" }
}

struct PlayerPlayTimeRow: Identifiable {
    let playerUUID: UUID
    let playerLabel: String
    let playHours: Double
    var id: String { playerUUID.uuidString }
}

struct SaveHeatRow: Identifiable {
    let saveKey: String
    let saveLabel: String
    let playHours: Double
    var id: String { saveKey }
}

struct PlayerSaveMatrixCell: Identifiable {
    let playerUUID: UUID
    let playerLabel: String
    let saveLabel: String
    let playHours: Double
    var id: String { "\(playerUUID.uuidString)|\(saveLabel)" }
}
