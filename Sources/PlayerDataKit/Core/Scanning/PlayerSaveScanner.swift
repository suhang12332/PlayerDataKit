import Foundation

enum PlayerSaveScanner {
    static func discoverPlayerUUIDs(savesRoot: URL) -> [String] {
        var uuids = Set<String>()
        for world in worldDirectories(under: savesRoot) {
            collectUUIDs(from: world.appendingPathComponent("stats", isDirectory: true), pathExtension: "json", into: &uuids)
        }
        return uuids.sorted()
    }

    static func buildReport(savesRoot: URL, playerUUID: String) throws -> PlayerSaveReport {
        let normalizedStem = MinecraftPlayerIdentity.normalizedIdString(playerUUID)
        let dashedStem = MinecraftPlayerIdentity.dashedUUIDString(fromNormalized: normalizedStem) ?? normalizedStem
        var records: [WorldPlayerRecord] = []

        let worlds = worldDirectories(under: savesRoot)
        records.reserveCapacity(worlds.count)
        for world in worlds {
            let name = world.lastPathComponent
            let statsURL = firstExistingFile(
                in: world,
                subdirectory: "stats",
                primaryStem: normalizedStem,
                secondaryStem: dashedStem,
                ext: "json"
            )
            let advURL = firstExistingFile(
                in: world,
                subdirectory: "advancements",
                primaryStem: normalizedStem,
                secondaryStem: dashedStem,
                ext: "json"
            )
            let hasStats = statsURL != nil
            let hasAdv = advURL != nil
            guard hasStats || hasAdv else { continue }

            let displayName = LevelDATReader.readWorldDisplayName(worldDirectory: world)

            var stats: MinecraftStatsSnapshot?
            if let statsURL {
                let data = try Data(contentsOf: statsURL)
                stats = try MinecraftStatsParser.parse(jsonData: data)
            }

            var advancements: MinecraftAdvancementsSnapshot?
            if let advURL {
                let data = try Data(contentsOf: advURL)
                advancements = try MinecraftAdvancementsParser.parse(jsonData: data)
            }

            records.append(
                WorldPlayerRecord(
                    worldDirectoryName: name,
                    displayName: displayName,
                    stats: stats,
                    advancements: advancements
                )
            )
        }

        records.sort { $0.worldDirectoryName.localizedCaseInsensitiveCompare($1.worldDirectoryName) == .orderedAscending }
        return PlayerSaveReport(playerUUID: normalizedStem, worlds: records)
    }

    static func buildAllPlayersMultiGameReports(
        entries: [(label: String, savesRoot: URL)]
    ) throws -> [MultiGamePlayerReport] {
        var allUUIDs = Set<String>()
        for entry in entries {
            allUUIDs.formUnion(discoverPlayerUUIDs(savesRoot: entry.savesRoot))
        }

        let sortedUUIDs = allUUIDs.sorted()
        var reports: [MultiGamePlayerReport] = []
        reports.reserveCapacity(sortedUUIDs.count)

        for uuid in sortedUUIDs {
            var out: [MultiGamePlayerReport.Entry] = []
            out.reserveCapacity(entries.count)
            for e in entries {
                let report = try buildReport(savesRoot: e.savesRoot, playerUUID: uuid)
                guard !report.worlds.isEmpty else { continue }
                out.append(MultiGamePlayerReport.Entry(gameLabel: e.label, savesRoot: e.savesRoot, report: report))
            }
            guard out.isEmpty == false else { continue }
            reports.append(MultiGamePlayerReport(playerUUID: uuid, entries: out))
        }

        return reports
    }

    private static func worldDirectories(under savesRoot: URL) -> [URL] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: savesRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        return contents.filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        }
    }

    private static func collectUUIDs(from directory: URL, pathExtension: String, into set: inout Set<String>) {
        let fm = FileManager.default
        guard fm.fileExists(atPath: directory.path) else { return }
        guard let files = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return
        }
        let extLower = pathExtension.lowercased()
        for url in files where url.pathExtension.lowercased() == extLower {
            let stem = url.deletingPathExtension().lastPathComponent
            let normalized = MinecraftPlayerIdentity.normalizedIdString(stem)
            guard normalized.count == 32 else { continue }
            set.insert(normalized)
        }
    }

    private static func firstExistingFile(
        in worldDirectory: URL,
        subdirectory: String,
        primaryStem: String,
        secondaryStem: String,
        ext: String
    ) -> URL? {
        let fm = FileManager.default
        let primaryCandidate = worldDirectory.appendingPathComponent("\(subdirectory)/\(primaryStem).\(ext)", isDirectory: false)
        if fm.fileExists(atPath: primaryCandidate.path) {
            return primaryCandidate
        }
        let secondaryCandidate = worldDirectory.appendingPathComponent("\(subdirectory)/\(secondaryStem).\(ext)", isDirectory: false)
        if fm.fileExists(atPath: secondaryCandidate.path) {
            return secondaryCandidate
        }
        return nil
    }
}

