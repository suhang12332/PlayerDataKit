import Foundation

extension UUID {
    /// Minecraft 存档文件名中的形式：无连字符、小写十六进制。
    var minecraftFileStem: String {
        uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }

    /// 从 `stats/<stem>.json` 的文件名解析 UUID。
    init?(minecraftFileStem stem: String) {
        let filtered = stem.lowercased().filter { $0.isHexDigit }
        guard filtered.count == 32 else { return nil }
        let s = String(filtered)
        let p1 = String(s.prefix(8))
        let p2 = String(s.dropFirst(8).prefix(4))
        let p3 = String(s.dropFirst(12).prefix(4))
        let p4 = String(s.dropFirst(16).prefix(4))
        let p5 = String(s.dropFirst(20).prefix(12))
        guard let u = UUID(uuidString: "\(p1)-\(p2)-\(p3)-\(p4)-\(p5)") else { return nil }
        self = u
    }
}

