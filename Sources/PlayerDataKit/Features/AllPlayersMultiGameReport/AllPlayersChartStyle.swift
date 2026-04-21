import SwiftUI

enum AllPlayersChartStyle {
    static let horizontalBarThickness: CGFloat = 18

    static let playerLeaderboardBarThickness: CGFloat = 10

    static let rowPitch: CGFloat = 80

    static let playerLeaderboardRowPitch: CGFloat = 60

    static func horizontalChartHeight(rowCount: Int) -> CGFloat {
        CGFloat(max(1, rowCount)) * rowPitch
    }

    static func playerLeaderboardHeight(rowCount: Int) -> CGFloat {
        CGFloat(max(1, rowCount)) * playerLeaderboardRowPitch
    }

    static let pieChartHeight: CGFloat = 240

    static let pieInnerRadiusRatio: CGFloat = 0.55
}

