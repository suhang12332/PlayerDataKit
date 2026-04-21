import Foundation

public enum MinecraftPlayerIdentity {
    public static func normalizedIdString(_ id: String) -> String {
        id.lowercased().filter { $0.isHexDigit }
    }

    public static func dashedUUIDString(fromNormalized id: String) -> String? {
        let normalized = normalizedIdString(id)
        guard normalized.count == 32 else { return nil }
        let p1 = String(normalized.prefix(8))
        let p2 = String(normalized.dropFirst(8).prefix(4))
        let p3 = String(normalized.dropFirst(12).prefix(4))
        let p4 = String(normalized.dropFirst(16).prefix(4))
        let p5 = String(normalized.dropFirst(20).prefix(12))
        return "\(p1)-\(p2)-\(p3)-\(p4)-\(p5)"
    }
}

