import Foundation

enum MultiGamePlayerReportLoader {
    static func loadAllPlayersReports(entries: [(label: String, savesRoot: URL)]) async throws -> [MultiGamePlayerReport] {
        try await Task(priority: .userInitiated) {
            try PlayerSaveScanner.buildAllPlayersMultiGameReports(entries: entries)
        }.value
    }
}

