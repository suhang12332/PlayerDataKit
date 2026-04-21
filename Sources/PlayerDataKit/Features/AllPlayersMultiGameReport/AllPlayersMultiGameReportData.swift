import Foundation

extension AllPlayersMultiGameReportView {
    func groupedPlayTimeByPlayer() -> [PlayerPlayTimeRow] {
        var hoursByPlayer: [String: Double] = [:]
        hoursByPlayer.reserveCapacity(reports.count)

        for report in reports {
            for entry in report.entries {
                let ticks = entry.report.totalPlayTimeTicks
                let hours = Formatting.hours(fromTicks: ticks)
                if hours > 0 {
                    hoursByPlayer[report.playerUUID, default: 0] += hours
                }
            }
        }

        let rawNameByUUID = Dictionary(uniqueKeysWithValues: reports.map { ($0.playerUUID, playerDisplayName($0.playerUUID)) })
        let labelByUUID = disambiguatedPlayerLabels(rawNameByUUID: rawNameByUUID)

        return hoursByPlayer.map { uuid, hours in
            PlayerPlayTimeRow(
                playerUUID: uuid,
                playerLabel: labelByUUID[uuid] ?? String(uuid.prefix(8)),
                playHours: hours
            )
        }
        .sorted { $0.playHours > $1.playHours }
    }

    func groupedHeatBySave() -> [SaveHeatRow] {
        var totals: [String: (label: String, hours: Double)] = [:]
        for report in reports {
            for entry in report.entries {
                for world in entry.report.worlds {
                    let ticks = world.stats?.playTimeTicks ?? 0
                    let hours = Formatting.hours(fromTicks: ticks)
                    let key = MultiGamePlayerReportFiltering.saveKey(
                        gameLabel: entry.gameLabel,
                        worldDirectoryName: world.worldDirectoryName
                    )
                    let label = MultiGamePlayerReportFiltering.saveDisplayLabel(gameLabel: entry.gameLabel, world: world)
                    var current = totals[key] ?? (label, 0)
                    current.label = label
                    current.hours += hours
                    totals[key] = current
                }
            }
        }
        return totals
            .map { SaveHeatRow(saveKey: $0.key, saveLabel: $0.value.label, playHours: $0.value.hours) }
            .sorted { $0.playHours > $1.playHours }
    }

    func groupedPlayTimeByGame() -> [(String, Double)] {
        var totals: [String: Int64] = [:]
        for report in reports {
            for entry in report.entries {
                totals[entry.gameLabel, default: 0] += entry.report.totalPlayTimeTicks
            }
        }
        return totals
            .map { ($0.key, Formatting.hours(fromTicks: $0.value)) }
            .sorted { $0.1 > $1.1 }
    }

    func playTimeByGamePerPlayerRows() -> [GamePlayerPlayRow] {
        let rawNameByUUID = Dictionary(
            uniqueKeysWithValues: reports.map { ($0.playerUUID, playerDisplayName($0.playerUUID)) }
        )
        let labelByUUID = disambiguatedPlayerLabels(rawNameByUUID: rawNameByUUID)

        var hoursBySavePlayer: [String: [String: Double]] = [:]
        var saveLabelByKey: [String: String] = [:]
        var totalsBySave: [String: Double] = [:]

        for report in reports {
            for entry in report.entries {
                for world in entry.report.worlds {
                    let ticks = world.stats?.playTimeTicks ?? 0
                    let hours = Formatting.hours(fromTicks: ticks)
                    guard hours > 0 else { continue }

                    let saveKey = MultiGamePlayerReportFiltering.saveKey(
                        gameLabel: entry.gameLabel,
                        worldDirectoryName: world.worldDirectoryName
                    )
                    let saveLabel = MultiGamePlayerReportFiltering.saveDisplayLabel(gameLabel: entry.gameLabel, world: world)
                    saveLabelByKey[saveKey] = saveLabel
                    totalsBySave[saveKey, default: 0] += hours

                    var byPlayer = hoursBySavePlayer[saveKey] ?? [:]
                    byPlayer[report.playerUUID, default: 0] += hours
                    hoursBySavePlayer[saveKey] = byPlayer
                }
            }
        }

        let totalsBySaveLabel: [String: Double] = Dictionary(
            uniqueKeysWithValues: totalsBySave.map { saveKey, total in
                (saveLabelByKey[saveKey] ?? saveKey, total)
            }
        )

        var rows: [GamePlayerPlayRow] = []
        for (saveKey, byPlayer) in hoursBySavePlayer {
            let saveLabel = saveLabelByKey[saveKey] ?? saveKey
            for (playerUUID, hours) in byPlayer {
                let playerLabel = labelByUUID[playerUUID] ?? String(playerUUID.prefix(8))
                rows.append(
                    GamePlayerPlayRow(
                        gameLabel: saveLabel,
                        playerUUID: playerUUID,
                        playHours: hours,
                        playerLabel: playerLabel
                    )
                )
            }
        }

        rows.sort {
            let t0 = totalsBySaveLabel[$0.gameLabel] ?? 0
            let t1 = totalsBySaveLabel[$1.gameLabel] ?? 0
            if t0 != t1 { return t0 > t1 }
            if $0.gameLabel != $1.gameLabel { return $0.gameLabel < $1.gameLabel }
            return $0.playerLabel < $1.playerLabel
        }
        return rows
    }

    func disambiguatedPlayerLabels(rawNameByUUID: [String: String]) -> [String: String] {
        let groups = Dictionary(grouping: rawNameByUUID.keys, by: { rawNameByUUID[$0] ?? "" })
        var out: [String: String] = [:]
        out.reserveCapacity(rawNameByUUID.count)
        for (rawName, uuids) in groups {
            let ordered = uuids.sorted()
            if ordered.count > 1 {
                for (index, uuid) in ordered.enumerated() {
                    out[uuid] = "\(rawName)#\(index + 1)"
                }
            } else if let uuid = ordered.first {
                out[uuid] = rawName
            }
        }
        return out
    }

    func playerSaveMatrixCells() -> [PlayerSaveMatrixCell] {
        var totalsByPlayer: [String: Double] = [:]
        var totalsBySave: [String: Double] = [:]
        var saveLabelByKey: [String: String] = [:]
        var matrix: [String: [String: Double]] = [:]

        for report in reports {
            for entry in report.entries {
                for world in entry.report.worlds {
                    let ticks = world.stats?.playTimeTicks ?? 0
                    let hours = Formatting.hours(fromTicks: ticks)
                    guard hours > 0 else { continue }
                    // 用目录名做 key，避免同名世界被合并。
                    let saveKey = MultiGamePlayerReportFiltering.saveKey(
                        gameLabel: entry.gameLabel,
                        worldDirectoryName: world.worldDirectoryName
                    )
                    let saveLabel = MultiGamePlayerReportFiltering.saveDisplayLabel(gameLabel: entry.gameLabel, world: world)
                    totalsByPlayer[report.playerUUID, default: 0] += hours
                    totalsBySave[saveKey, default: 0] += hours
                    saveLabelByKey[saveKey] = saveLabel
                    var row = matrix[report.playerUUID] ?? [:]
                    row[saveKey, default: 0] += hours
                    matrix[report.playerUUID] = row
                }
            }
        }

        if matrix.isEmpty { return [] }

        let topPlayers = totalsByPlayer.sorted { $0.value > $1.value }.prefix(20).map(\.key)
        let topSaves = totalsBySave.sorted { $0.value > $1.value }.prefix(20).map(\.key)
        let rawNameByUUID = Dictionary(
            uniqueKeysWithValues: reports.map { ($0.playerUUID, playerDisplayName($0.playerUUID)) }
        )
        let labelByUUID = disambiguatedPlayerLabels(rawNameByUUID: rawNameByUUID)

        var cells: [PlayerSaveMatrixCell] = []
        for playerUUID in topPlayers {
            let playerLabel = labelByUUID[playerUUID] ?? playerDisplayName(playerUUID)
            let row = matrix[playerUUID] ?? [:]
            for saveKey in topSaves {
                let saveLabel = saveLabelByKey[saveKey] ?? saveKey
                let hours = row[saveKey] ?? 0
                cells.append(
                    PlayerSaveMatrixCell(
                        playerUUID: playerUUID,
                        playerLabel: playerLabel,
                        saveLabel: saveLabel,
                        playHours: hours
                    )
                )
            }
        }

        return cells
    }
}
