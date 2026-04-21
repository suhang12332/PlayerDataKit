import Charts
import SwiftUI

private struct ShareSliceRow: Identifiable {
    let label: String
    let playHours: Double
    var id: String { label }
}

private struct PlayerSaveFlatRow: Identifiable {
    let playerUUID: String
    let playerLabel: String
    let saveLabel: String
    let hours: Double
    var id: String { "\(playerUUID)|\(saveLabel)" }
}

extension AllPlayersMultiGameReportView {
    func sharePieChartsSection(playerRows: [PlayerPlayTimeRow], heatRows: [SaveHeatRow]) -> some View {
        let playerSlices = playerShareRows(from: playerRows, limit: 12)
        let saveSlices = saveShareRows(from: heatRows, limit: 12)

        return Group {
            if playerSlices.isEmpty == false || saveSlices.isEmpty == false {
                VStack(alignment: .leading, spacing: 8) {
                    Text(PDKL10n.string("allPlayers.report.share.title"))
                        .font(.headline)
                    Text(PDKL10n.string("allPlayers.report.share.subtitle"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .top, spacing: 16) {
                        if playerSlices.isEmpty == false {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(PDKL10n.string("allPlayers.report.share.player"))
                                    .font(.subheadline.weight(.semibold))
                                pieOrBar(rows: playerSlices, seriesName: PDKL10n.string("allPlayers.legend.player"))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if saveSlices.isEmpty == false {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(PDKL10n.string("allPlayers.report.share.save"))
                                    .font(.subheadline.weight(.semibold))
                                pieOrBar(rows: saveSlices, seriesName: PDKL10n.string("allPlayers.legend.save"))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func pieOrBar(rows: [ShareSliceRow], seriesName: String) -> some View {
        Chart(rows) { row in
            SectorMark(
                angle: .value(PDKL10n.string("allPlayers.axis.hours"), row.playHours),
                innerRadius: .ratio(AllPlayersChartStyle.pieInnerRadiusRatio),
                angularInset: 1.0
            )
            .foregroundStyle(by: .value(seriesName, row.label))
        }
        .chartLegend(position: .bottom, alignment: .leading)
        .frame(height: AllPlayersChartStyle.pieChartHeight)
    }

    private func playerShareRows(from rows: [PlayerPlayTimeRow], limit: Int) -> [ShareSliceRow] {
        let top = rows.prefix(max(1, limit))
        return top.map { ShareSliceRow(label: $0.playerLabel, playHours: $0.playHours) }
    }

    private func saveShareRows(from rows: [SaveHeatRow], limit: Int) -> [ShareSliceRow] {
        let top = rows.prefix(max(1, limit))
        return top.map { ShareSliceRow(label: $0.saveLabel, playHours: $0.playHours) }
            .filter { $0.playHours > 0 }
    }

    func playerSaveMatrixSection(cells: [PlayerSaveMatrixCell]) -> some View {
        let flatRows: [PlayerSaveFlatRow] = cells.map { cell in
            PlayerSaveFlatRow(
                playerUUID: cell.playerUUID,
                playerLabel: cell.playerLabel,
                saveLabel: cell.saveLabel,
                hours: cell.playHours
            )
        }

        return Group {
            if flatRows.isEmpty == false {
                VStack(alignment: .leading, spacing: 8) {
                    Text(PDKL10n.string("allPlayers.report.matrix.title"))
                        .font(.headline)
                    GeometryReader { proxy in
                        ScrollView(.horizontal) {
                            Table(flatRows) {
                                TableColumn(PDKL10n.string("allPlayers.table.player")) { row in
                                    HStack(spacing: 6) {
                                        playerAvatarView(row.playerUUID)
                                        Text(row.playerLabel)
                                            .lineLimit(1)
                                    }
                                }
                                .width(min: 140, ideal: 180)
                                TableColumn(PDKL10n.string("allPlayers.table.save")) { row in
                                    Text(row.saveLabel)
                                        .lineLimit(1)
                                }
                                .width(min: 220, ideal: 320)
                                TableColumn(PDKL10n.string("allPlayers.table.duration")) { row in
                                    Text(
                                        row.hours > 0
                                            ? String(format: "%.2f h", row.hours)
                                            : "—"
                                    )
                                        .foregroundStyle(row.hours > 0 ? .primary : .secondary)
                                }
                                .width(min: 90, ideal: 110)
                            }
                            // Table 在横向 ScrollView 中需要显式宽度，避免布局塌陷为 0。
                            .frame(minWidth: max(proxy.size.width, 450), alignment: .leading)
                            .frame(minHeight: CGFloat(max(220, flatRows.count * 24)))
                        }
                    }
                    .frame(height: CGFloat(max(220, flatRows.count * 24)))
                }
            }
        }
    }

    /// 每个游戏存档一条横条，按玩家分段堆叠；图例为 ``playerDisplayName`` 返回的展示名。
    func playTimeByGamePerPlayerChart(rows: [GamePlayerPlayRow]) -> some View {
        return Group {
            if rows.isEmpty == false {
                VStack(alignment: .leading, spacing: 8) {
                    Text(PDKL10n.string("allPlayers.report.perSavePerPlayer.title"))
                        .font(.headline)
                    Text(PDKL10n.string("allPlayers.report.perSavePerPlayer.subtitle"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Chart(rows) { row in
                        BarMark(
                            x: .value(PDKL10n.string("allPlayers.axis.hours"), row.playHours),
                            y: .value(PDKL10n.string("allPlayers.axis.save"), row.gameLabel),
                            height: .fixed(AllPlayersChartStyle.horizontalBarThickness)
                        )
                        .foregroundStyle(by: .value(PDKL10n.string("allPlayers.legend.player"), row.playerLabel))
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            if let label = value.as(String.self) {
                                AxisValueLabel {
                                    Text(label)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .chartXAxisLabel(PDKL10n.string("allPlayers.axis.hours"), position: .bottom)
                    .chartLegend(.hidden)
                    .frame(minHeight: AllPlayersChartStyle.horizontalChartHeight(rowCount: uniqueGameCount(rows)))
                }
            }
        }
    }

    private func uniqueGameCount(_ rows: [GamePlayerPlayRow]) -> Int {
        Set(rows.map(\.gameLabel)).count
    }

    func playerPlayTimeLeaderboard(rows: [PlayerPlayTimeRow]) -> some View {
        Group {
            if rows.isEmpty == false {
                VStack(alignment: .leading, spacing: 8) {
                    Text(PDKL10n.string("allPlayers.report.playerLeaderboard.title"))
                        .font(.headline)
                    Text(PDKL10n.string("allPlayers.report.playerLeaderboard.subtitle"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    let top = Array(rows.prefix(20))
                    let avatarMap = Dictionary(uniqueKeysWithValues: top.map { ($0.playerLabel, $0.playerUUID) })
                    let hourTextMap = Dictionary(
                        uniqueKeysWithValues: top.map {
                            ($0.playerLabel, PDKL10n.format("allPlayers.format.hours.compact", $0.playHours))
                        }
                    )
                    Chart(top) { row in
                        BarMark(
                            x: .value(PDKL10n.string("allPlayers.axis.hours"), row.playHours),
                            y: .value(PDKL10n.string("allPlayers.axis.player"), row.playerLabel),
                            height: .fixed(AllPlayersChartStyle.playerLeaderboardBarThickness)
                        )
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            if let label = value.as(String.self),
                               let uuid = avatarMap[label] {
                                AxisValueLabel {
                                    HStack(spacing: 4) {
                                        playerAvatarView(uuid)
                                        Text("\(label)  \(hourTextMap[label] ?? "")")
                                            .lineLimit(1)
                                            .bold()
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                    .chartXAxisLabel(PDKL10n.string("allPlayers.axis.hours"), position: .bottom)
                    .frame(minHeight: AllPlayersChartStyle.playerLeaderboardHeight(rowCount: top.count))
                }
            }
        }
    }

    func saveHeatLeaderboard(rows: [SaveHeatRow]) -> some View {
        Group {
            if rows.isEmpty == false {
                VStack(alignment: .leading, spacing: 8) {
                    Text(PDKL10n.string("allPlayers.report.saveLeaderboard.title"))
                        .font(.headline)
                    Text(PDKL10n.string("allPlayers.report.saveLeaderboard.subtitle"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    let top = Array(rows.prefix(20))
                    let hourTextMap = Dictionary(
                        uniqueKeysWithValues: top.map {
                            ($0.saveLabel, PDKL10n.format("allPlayers.format.hours.compact", $0.playHours))
                        }
                    )
                    Chart(top) { row in
                        BarMark(
                            x: .value(PDKL10n.string("allPlayers.axis.hours"), row.playHours),
                            y: .value(PDKL10n.string("allPlayers.axis.save"), row.saveLabel),
                            height: .fixed(AllPlayersChartStyle.horizontalBarThickness)
                        )
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            if let label = value.as(String.self) {
                                AxisValueLabel {
                                    Text("\(label)  \(hourTextMap[label] ?? "")")
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .chartXAxisLabel(PDKL10n.string("allPlayers.axis.hours"), position: .bottom)
                    .frame(minHeight: AllPlayersChartStyle.horizontalChartHeight(rowCount: top.count))
                }
            }
        }
    }
}
