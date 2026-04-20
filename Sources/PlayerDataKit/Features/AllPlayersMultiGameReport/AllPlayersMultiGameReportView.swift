import Charts
import SwiftUI

/// 展示「全部玩家 x 全部游戏实例」的汇总统计。
///
/// 传入 `PlayerSaveScanner.buildAllPlayersMultiGameReports(entries:)` 的结果即可使用。
///
/// - Parameters:
///   - playerDisplayName: 将玩家 UUID 映射为展示名（如图表「按玩家」图例）；主应用应从账户列表解析昵称。
struct AllPlayersMultiGameReportView: View {
    private struct DashboardData {
        let playerRows: [PlayerPlayTimeRow]
        let heatRows: [SaveHeatRow]
        let gameRows: [(String, Double)]
        let gamePerPlayerRows: [GamePlayerPlayRow]
        let matrixCells: [PlayerSaveMatrixCell]
    }

    let reports: [MultiGamePlayerReport]
    let playerDisplayName: (UUID) -> String
    let playerAvatarView: (UUID) -> AnyView

    init(
        reports: [MultiGamePlayerReport],
        playerDisplayName: @escaping (UUID) -> String = { uuid in
            String(uuid.uuidString.prefix(8))
        },
        playerAvatarView: @escaping (UUID) -> AnyView = { _ in
            AnyView(
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            )
        }
    ) {
        self.reports = reports
        self.playerDisplayName = playerDisplayName
        self.playerAvatarView = playerAvatarView
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if reports.isEmpty {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    let dashboardData = makeDashboardData()
                    AllPlayersGlobalOverviewContent(reports: reports)
                    playerPlayTimeLeaderboard(rows: dashboardData.playerRows)
                    sharePieChartsSection(playerRows: dashboardData.playerRows, heatRows: dashboardData.heatRows)
                    saveHeatLeaderboard(rows: dashboardData.heatRows)
                    playTimeByGamePerPlayerChart(rows: dashboardData.gamePerPlayerRows)
                    totalPlayTimePerGameChart(rows: dashboardData.gameRows)
                    playerSaveMatrixSection(cells: dashboardData.matrixCells)
                }
            }
            .padding()
        }
    }

    private func makeDashboardData() -> DashboardData {
        DashboardData(
            playerRows: groupedPlayTimeByPlayer(),
            heatRows: groupedHeatBySave(),
            gameRows: groupedPlayTimeByGame(),
            gamePerPlayerRows: playTimeByGamePerPlayerRows(),
            matrixCells: playerSaveMatrixCells()
        )
    }

    private func totalPlayTimePerGameChart(rows: [(String, Double)]) -> some View {
        return VStack(alignment: .leading, spacing: 8) {
            Text(PDKL10n.string("allPlayers.report.totalPlayTimePerGame.title"))
                .font(.headline)
            Chart(rows, id: \.0) { row in
                BarMark(
                    x: .value(PDKL10n.string("allPlayers.axis.hours"), row.1),
                    y: .value(PDKL10n.string("allPlayers.axis.game"), row.0),
                    height: .fixed(AllPlayersChartStyle.horizontalBarThickness)
                )
                .annotation(position: .trailing) {
                    Text(PDKL10n.format("allPlayers.format.hours.compact", row.1))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
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
            .frame(minHeight: AllPlayersChartStyle.horizontalChartHeight(rowCount: rows.count))
        }
    }
}
