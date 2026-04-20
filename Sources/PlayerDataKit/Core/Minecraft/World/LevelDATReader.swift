import Foundation

enum LevelDATReader {
    /// 读取世界文件夹 `level.dat` 中的展示名 `LevelName`（失败时返回 nil）。
    static func readWorldDisplayName(worldDirectory: URL) -> String? {
        let url = worldDirectory.appendingPathComponent("level.dat", isDirectory: false)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let raw: Data
        do {
            raw = try Data(contentsOf: url)
        } catch {
            return nil
        }
        guard !raw.isEmpty else { return nil }
        guard let nbt = try? NBTParser(data: raw).parse() else { return nil }
        let dataTag = (nbt["Data"] as? [String: Any]) ?? nbt
        if let name = dataTag["LevelName"] as? String, !name.isEmpty {
            return name
        }
        return nil
    }
}

