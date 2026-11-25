import SwiftUI

struct NookUser: Identifiable, Codable, Hashable {
    let id: String
    var email: String
    var pseudo: String
    var avatarId: Int
    var xp = 0
    var checkins = 0
    var badges: [String] = []
    var isPlus = false

    var dict: [String: Any] {
        ["email": email, "pseudo": pseudo, "avatarId": avatarId, "xp": xp, "checkins": checkins, "badges": badges, "isPlus": isPlus]
    }
}

enum UserLevel: Int, CaseIterable {
    case stagiaire, habitue, maire
    var minXP: Int { [0, 300, 1000][rawValue] }
    var titleKey: String { "level.\(["stagiaire", "habitue", "maire"][rawValue])" }
    var icon: String { ["leaf.fill", "cup.and.saucer.fill", "crown.fill"][rawValue] }
    var next: UserLevel? { UserLevel(rawValue: rawValue + 1) }
    static func level(for xp: Int) -> UserLevel { allCases.last(where: { xp >= $0.minXP }) ?? .stagiaire }
    static func progress(_ xp: Int) -> Double {
        let l = level(for: xp)
        guard let n = l.next else { return 1 }
        return min(1, Double(xp - l.minXP) / Double(n.minXP - l.minXP))
    }
}

enum Badge: String, CaseIterable, Codable {
    case firstCheckIn, tenCheckIns, earlyBird, nightOwl, reviewer, habitue, maire, explorer
    var titleKey: String { "badge.\(rawValue)" }
    var icon: String {
        switch self {
        case .firstCheckIn: return "mappin.and.ellipse"
        case .tenCheckIns: return "10.circle.fill"
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .reviewer: return "text.bubble.fill"
        case .habitue: return "cup.and.saucer.fill"
        case .maire: return "crown.fill"
        case .explorer: return "map.fill"
        }
    }
    var color: Color {
        switch self {
        case .firstCheckIn: return PixelTheme.green
        case .tenCheckIns: return PixelTheme.orange
        case .earlyBird: return PixelTheme.lamp
        case .nightOwl: return Color(hex: 0x9B5DE5)
        case .reviewer: return PixelTheme.rose
        case .habitue: return Color(hex: 0x5BC0EB)
        case .maire: return Color(hex: 0xFFB703)
        case .explorer: return Color(hex: 0x2A9D8F)
        }
    }
}
