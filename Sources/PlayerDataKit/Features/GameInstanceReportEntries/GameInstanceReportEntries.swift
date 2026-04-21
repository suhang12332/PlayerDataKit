import Foundation

public struct GameInstanceReportSource: Sendable, Equatable {
    let displayName: String
    let profileRoot: URL

    public init(displayName: String, profileRoot: URL) {
        self.displayName = displayName
        self.profileRoot = profileRoot
    }
}

public enum GameInstanceReportEntries {
    public static func build(
        sources: [GameInstanceReportSource],
        savesDirectoryName: String = "saves"
    ) -> [(label: String, savesRoot: URL)] {
        let fm = FileManager.default
        var nameOccurrences: [String: Int] = [:]
        nameOccurrences.reserveCapacity(sources.count)
        for source in sources {
            nameOccurrences[source.displayName, default: 0] += 1
        }
        var nameCounter: [String: Int] = [:]
        nameCounter.reserveCapacity(nameOccurrences.count)
        return sources.compactMap { source in
            let currentIndex = (nameCounter[source.displayName] ?? 0) + 1
            nameCounter[source.displayName] = currentIndex

            let savesRoot = source.profileRoot.appendingPathComponent(savesDirectoryName, isDirectory: true)
            guard fm.fileExists(atPath: savesRoot.path) else { return nil }

            let hasDuplicateName = (nameOccurrences[source.displayName] ?? 0) > 1
            let label = hasDuplicateName ? "\(source.displayName) #\(currentIndex)" : source.displayName
            return (label: label, savesRoot: savesRoot)
        }
    }
}

