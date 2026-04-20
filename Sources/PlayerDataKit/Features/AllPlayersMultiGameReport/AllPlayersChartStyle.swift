import SwiftUI

/// 统一 AllPlayersMultiGameReport 系列图表的视觉尺寸。
enum AllPlayersChartStyle {
    /// 横向条形图每条的厚度（Y 方向的高度）。
    static let horizontalBarThickness: CGFloat = 18

    /// 「玩家累计游玩时长排行榜」单独条形厚度。
    static let playerLeaderboardBarThickness: CGFloat = 10

    /// 每条/每行预留的总高度（条厚 + 间距的综合效果），用于计算 `frame(minHeight:)`。
    static let rowPitch: CGFloat = 80

    /// 「玩家累计游玩时长排行榜」单独行高，避免排行榜条间距过大。
    static let playerLeaderboardRowPitch: CGFloat = 60

    /// 按行数计算横向图表总高度，保证不同图表的行间距规则一致。
    static func horizontalChartHeight(rowCount: Int) -> CGFloat {
        CGFloat(max(1, rowCount)) * rowPitch
    }

    /// 排行榜按行数计算高度（更紧凑）。
    static func playerLeaderboardHeight(rowCount: Int) -> CGFloat {
        CGFloat(max(1, rowCount)) * playerLeaderboardRowPitch
    }

    /// 饼图（macOS 14+ SectorMark）固定高度，保证与条形图整体一致。
    static let pieChartHeight: CGFloat = 240

    /// 饼图的中空比例（donut）。
    static let pieInnerRadiusRatio: CGFloat = 0.55
}

