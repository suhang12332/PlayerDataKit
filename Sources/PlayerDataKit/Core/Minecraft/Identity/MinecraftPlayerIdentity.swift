import Foundation

/// 与 ``UUID`` 的 `minecraftFileStem` 风格一致，用于与账户列表中的玩家 id 字符串比较。
public enum MinecraftPlayerIdentity {
    public static func normalizedIdString(_ id: String) -> String {
        id.lowercased().replacingOccurrences(of: "-", with: "")
    }
}

