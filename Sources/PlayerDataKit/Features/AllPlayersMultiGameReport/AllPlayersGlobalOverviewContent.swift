import SwiftUI

// MARK: - 全部玩家 x 全部存档（全局总览）

private struct AllPlayersGlobalMetrics: Sendable {
    let gameInstanceCount: Int
    let worldCount: Int
    let totalPlayTimeTicks: Int64
    let totalDeaths: Int64
    let mobKills: Int64
    let playerKills: Int64
    let advancementsCompleted: Int
    let advancementsTotal: Int
    let walkKm: Double
    let sprintKm: Double
    let swimKm: Double
    let crouchKm: Double
    let climbKm: Double
    let aviateKm: Double

    init(reports: [MultiGamePlayerReport]) {
        let entries = reports.flatMap(\.entries)
        gameInstanceCount = Set(entries.map(\.gameLabel)).count
        let worlds = entries.flatMap { $0.report.worlds }
        worldCount = worlds.count
        totalPlayTimeTicks = reports.reduce(Int64(0)) { partial, report in
            partial + report.entries.reduce(Int64(0)) { $0 + $1.report.totalPlayTimeTicks }
        }
        totalDeaths = worlds.reduce(0) { $0 + ($1.stats?.deaths ?? 0) }
        mobKills = worlds.reduce(0) { $0 + ($1.stats?.mobKills ?? 0) }
        playerKills = worlds.reduce(0) { $0 + ($1.stats?.playerKills ?? 0) }
        advancementsCompleted = worlds.reduce(0) { $0 + ($1.advancements?.completedCount ?? 0) }
        advancementsTotal = worlds.reduce(0) { $0 + ($1.advancements?.totalCount ?? 0) }
        let walk = worlds.compactMap(\.stats?.walkCm).reduce(0, +)
        let sprint = worlds.compactMap(\.stats?.sprintCm).reduce(0, +)
        let swim = worlds.compactMap(\.stats?.swimCm).reduce(0, +)
        let crouch = worlds.compactMap(\.stats?.crouchCm).reduce(0, +)
        let climb = worlds.compactMap(\.stats?.climbCm).reduce(0, +)
        let aviate = worlds.compactMap(\.stats?.aviateCm).reduce(0, +)
        walkKm = Formatting.kilometers(fromCm: walk)
        sprintKm = Formatting.kilometers(fromCm: sprint)
        swimKm = Formatting.kilometers(fromCm: swim)
        crouchKm = Formatting.kilometers(fromCm: crouch)
        climbKm = Formatting.kilometers(fromCm: climb)
        aviateKm = Formatting.kilometers(fromCm: aviate)
    }
}

/// 跨所有玩家、所有 `saves` 根目录、所有世界的汇总指标（主界面推荐用这一层）。
struct AllPlayersGlobalOverviewContent: View {
    let reports: [MultiGamePlayerReport]

    init(reports: [MultiGamePlayerReport]) {
        self.reports = reports
    }

    var body: some View {
        let metrics = AllPlayersGlobalMetrics(reports: reports)
        let totalKills = metrics.mobKills + metrics.playerKills
        let advancementRate = ratio(metrics.advancementsCompleted, metrics.advancementsTotal)
        let mobKillShare = ratio(metrics.mobKills, totalKills)
        let playerKillShare = ratio(metrics.playerKills, totalKills)

        let totalMoveKm = metrics.walkKm + metrics.sprintKm + metrics.swimKm
        let walkShare = totalMoveKm > 0 ? metrics.walkKm / totalMoveKm : 0
        let sprintShare = totalMoveKm > 0 ? metrics.sprintKm / totalMoveKm : 0
        let swimShare = totalMoveKm > 0 ? metrics.swimKm / totalMoveKm : 0

        let totalOtherMoveKm = metrics.crouchKm + metrics.climbKm + metrics.aviateKm
        let crouchShare = totalOtherMoveKm > 0 ? metrics.crouchKm / totalOtherMoveKm : 0
        let climbShare = totalOtherMoveKm > 0 ? metrics.climbKm / totalOtherMoveKm : 0
        let aviateShare = totalOtherMoveKm > 0 ? metrics.aviateKm / totalOtherMoveKm : 0

        if !reports.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(PDKL10n.string("allPlayers.overview.title"))
                            .font(.headline)
                        Text(PDKL10n.string("allPlayers.overview.subtitle"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    scaleHeaderSummary(metrics: metrics)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 280), spacing: 12)],
                    alignment: .leading,
                    spacing: 12
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(PDKL10n.string("allPlayers.overview.combatProgress"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 8) {
                            shareGauge(
                                title: PDKL10n.string("allPlayers.overview.progressRate"),
                                value: advancementRate,
                                detail: "\(metrics.advancementsCompleted)/\(metrics.advancementsTotal)",
                                tint: .green
                            )
                            shareGauge(
                                title: PDKL10n.string("allPlayers.overview.mobKillShare"),
                                value: mobKillShare,
                                detail: "\(metrics.mobKills)/\(totalKills)",
                                tint: .orange
                            )
                            shareGauge(
                                title: PDKL10n.string("allPlayers.overview.playerKillShare"),
                                value: playerKillShare,
                                detail: "\(metrics.playerKills)/\(totalKills)",
                                tint: .red
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(PDKL10n.string("allPlayers.overview.movement"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 8) {
                            shareGauge(
                                title: PDKL10n.string("allPlayers.overview.walkShare"),
                                value: walkShare,
                                detail: distanceRatioDetail(metrics.walkKm, totalMoveKm),
                                tint: .mint
                            )
                            shareGauge(
                                title: PDKL10n.string("allPlayers.overview.sprintShare"),
                                value: sprintShare,
                                detail: distanceRatioDetail(metrics.sprintKm, totalMoveKm),
                                tint: .indigo
                            )
                            shareGauge(
                                title: PDKL10n.string("allPlayers.overview.swimShare"),
                                value: swimShare,
                                detail: distanceRatioDetail(metrics.swimKm, totalMoveKm),
                                tint: .cyan
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(PDKL10n.string("allPlayers.overview.otherMovement"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 8) {
                            shareGauge(
                                title: PDKL10n.string("allPlayers.overview.crouchShare"),
                                value: crouchShare,
                                detail: distanceRatioDetail(metrics.crouchKm, totalOtherMoveKm),
                                tint: .brown
                            )
                            shareGauge(
                                title: PDKL10n.string("allPlayers.overview.climbShare"),
                                value: climbShare,
                                detail: distanceRatioDetail(metrics.climbKm, totalOtherMoveKm),
                                tint: .yellow
                            )
                            shareGauge(
                                title: PDKL10n.string("allPlayers.overview.aviateShare"),
                                value: aviateShare,
                                detail: distanceRatioDetail(metrics.aviateKm, totalOtherMoveKm),
                                tint: .teal
                            )
                        }
                    }
                }
            }
        }
    }

    private func scaleHeaderSummary(metrics: AllPlayersGlobalMetrics) -> some View {
        HStack(spacing: 0) {
            scaleHeaderSegment(
                icon: "shippingbox",
                title: PDKL10n.string("allPlayers.overview.metric.gameInstances"),
                value: "\(metrics.gameInstanceCount)"
            )
            Text(" · ")
                .foregroundStyle(.tertiary)
            scaleHeaderSegment(
                icon: "globe",
                title: PDKL10n.string("allPlayers.overview.metric.worldRecords"),
                value: "\(metrics.worldCount)"
            )
            Text(" · ")
                .foregroundStyle(.tertiary)
            scaleHeaderSegment(
                icon: "clock",
                title: PDKL10n.string("allPlayers.overview.metric.totalPlayTime"),
                value: Formatting.shortDurationDescription(fromTicks: metrics.totalPlayTimeTicks)
            )
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }

    private func scaleHeaderSegment(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(title)
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
    }

    private func shareGauge(title: String, value: Double, detail: String, tint: Color) -> some View {
        Gauge(value: min(max(value, 0), 1), in: 0 ... 1) {
            Text(title)
        } currentValueLabel: {
            HStack(spacing: 8) {
                Text(String(format: "%.0f%%", value * 100))
                Spacer(minLength: 8)
                Text(detail)
            }
            .monospacedDigit()
        } minimumValueLabel: {
            Text("0%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } maximumValueLabel: {
            Text("100%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .tint(tint)
        .gaugeStyle(.accessoryLinearCapacity)
    }

    private func distanceRatioDetail(_ part: Double, _ total: Double) -> String {
        String(format: "%.2f/%.2f km", part, total)
    }

    private func ratio<T: BinaryInteger>(_ numerator: T, _ denominator: T) -> Double {
        guard denominator > 0 else { return 0 }
        return Double(numerator) / Double(denominator)
    }
}
