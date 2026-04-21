import Foundation

struct MinecraftStatsSnapshot: Sendable {
    let playTimeTicks: Int64?
    let deaths: Int64?
    let mobKills: Int64?
    let playerKills: Int64?
    let walkCm: Int64?
    let sprintCm: Int64?
    let swimCm: Int64?
    let crouchCm: Int64?
    let climbCm: Int64?
    let aviateCm: Int64?

    init(
        playTimeTicks: Int64?,
        deaths: Int64?,
        mobKills: Int64?,
        playerKills: Int64?,
        walkCm: Int64?,
        sprintCm: Int64?,
        swimCm: Int64?,
        crouchCm: Int64?,
        climbCm: Int64?,
        aviateCm: Int64?
    ) {
        self.playTimeTicks = playTimeTicks
        self.deaths = deaths
        self.mobKills = mobKills
        self.playerKills = playerKills
        self.walkCm = walkCm
        self.sprintCm = sprintCm
        self.swimCm = swimCm
        self.crouchCm = crouchCm
        self.climbCm = climbCm
        self.aviateCm = aviateCm
    }
}

enum MinecraftStatsParser {
    private static let customPrefix = "minecraft:custom"
    private static let keyPlayTime = "minecraft:play_time"
    private static let keyDeaths = "minecraft:deaths"
    private static let keyMobKills = "minecraft:mob_kills"
    private static let keyPlayerKills = "minecraft:player_kills"
    private static let keyWalk = "minecraft:walk_one_cm"
    private static let keySprint = "minecraft:sprint_one_cm"
    private static let keySwim = "minecraft:swim_one_cm"
    private static let keyCrouch = "minecraft:crouch_one_cm"
    private static let keyClimb = "minecraft:climb_one_cm"
    private static let keyAviate = "minecraft:aviate_one_cm"

    static func parse(jsonData: Data) throws -> MinecraftStatsSnapshot {
        let obj = try JSONSerialization.jsonObject(with: jsonData, options: [])
        guard let root = obj as? [String: Any] else {
            return emptySnapshot()
        }
        guard let stats = root["stats"] as? [String: Any],
              let custom = stats[customPrefix] as? [String: Any] else {
            return emptySnapshot()
        }

        func pick(_ key: String) -> Int64? {
            guard let v = custom[key] else { return nil }
            return numberToInt64(v)
        }

        return MinecraftStatsSnapshot(
            playTimeTicks: pick(keyPlayTime),
            deaths: pick(keyDeaths),
            mobKills: pick(keyMobKills),
            playerKills: pick(keyPlayerKills),
            walkCm: pick(keyWalk),
            sprintCm: pick(keySprint),
            swimCm: pick(keySwim),
            crouchCm: pick(keyCrouch),
            climbCm: pick(keyClimb),
            aviateCm: pick(keyAviate)
        )
    }

    private static func emptySnapshot() -> MinecraftStatsSnapshot {
        MinecraftStatsSnapshot(
            playTimeTicks: nil,
            deaths: nil,
            mobKills: nil,
            playerKills: nil,
            walkCm: nil,
            sprintCm: nil,
            swimCm: nil,
            crouchCm: nil,
            climbCm: nil,
            aviateCm: nil
        )
    }

    private static func numberToInt64(_ v: Any) -> Int64? {
        if let i = v as? Int64 { return i }
        if let i = v as? Int { return Int64(i) }
        if let i = v as? UInt64 { return Int64(i) }
        if let i = v as? Double { return Int64(i) }
        return nil
    }
}

