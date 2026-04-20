import Foundation

enum MultiGamePlayerReportLoader {
    /// 在后台线程构建「全部玩家 x 多实例」报表，避免阻塞主线程。
    static func loadAllPlayersReports(entries: [(label: String, savesRoot: URL)]) async throws -> [MultiGamePlayerReport] {
        try await Task(priority: .userInitiated) {
            try PlayerSaveScanner.buildAllPlayersMultiGameReports(entries: entries)
        }.value
    }
}

