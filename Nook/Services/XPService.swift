import Foundation

struct XPResult {
    let gained: Int
    let oldXP: Int
    let user: NookUser
    let leveledUp: Bool
    let newLevel: UserLevel
    let newBadges: [Badge]
}

enum XPService {
    static func xp(for c: CheckIn) -> Int {
        var x = 20
        if !c.comment.isEmpty { x += 10 }
        if c.coffeePrice != nil { x += 5 }
        return x
    }

    static func apply(_ c: CheckIn, to user: NookUser) -> XPResult {
        var u = user
        let oldLevel = UserLevel.level(for: u.xp)
        let gained = xp(for: c)
        u.xp += gained
        u.checkins += 1
        let newLevel = UserLevel.level(for: u.xp)
        var unlocked: [Badge] = []
        func unlock(_ b: Badge, _ cond: Bool) {
            if cond && !u.badges.contains(b.rawValue) { u.badges.append(b.rawValue); unlocked.append(b) }
        }
        let hour = Calendar.current.component(.hour, from: c.createdAt)
        unlock(.firstCheckIn, u.checkins >= 1)
        unlock(.tenCheckIns, u.checkins >= 10)
        unlock(.earlyBird, hour < 8)
        unlock(.nightOwl, hour >= 22)
        unlock(.reviewer, !c.comment.isEmpty)
        unlock(.habitue, newLevel.rawValue >= UserLevel.habitue.rawValue)
        unlock(.maire, newLevel == .maire)
        return XPResult(gained: gained, oldXP: user.xp, user: u, leveledUp: newLevel != oldLevel,
                        newLevel: newLevel, newBadges: unlocked)
    }
}
