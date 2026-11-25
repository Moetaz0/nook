import SwiftUI

struct ProfileView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var board: LoadState<[NookUser]> = .idle

    private func loadBoard() async {
        board = .loading
        do { let l = try await env.data.leaderboard(); board = l.isEmpty ? .empty : .loaded(l) }
        catch { board = .failed(AppError.key(for: error)) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if let u = env.auth.user {
                        let level = UserLevel.level(for: u.xp)
                        PixelCard {
                            HStack(spacing: 14) {
                                PixelAvatarView(id: u.avatarId, size: 64)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(u.pseudo).pixelFont(14)
                                    Label { Text(LocalizedStringKey(level.titleKey)) } icon: { Image(systemName: level.icon) }
                                        .pixelFont(10).foregroundStyle(PixelTheme.accent)
                                }
                                Spacer()
                            }
                        }
                        PixelCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(verbatim: "\(u.xp) XP").pixelFont(14)
                                    Spacer()
                                    if let n = level.next {
                                        Text(verbatim: "→ \(n.minXP) XP").pixelFont(9).opacity(0.7)
                                    } else { Text("profile.maxlevel").pixelFont(9) }
                                }
                                XPBarView(progress: UserLevel.progress(u.xp))
                                Text(verbatim: "\(u.checkins) check-ins").font(.caption).opacity(0.7)
                            }
                        }
                        BadgeGrid(unlocked: Set(u.badges))
                        LeaderboardView(state: board, currentUID: u.id) { Task { await loadBoard() } }
                    } else {
                        EmptyStateView()
                    }
                }
                .padding()
            }
            .background(PixelBackground())
            .navigationTitle("tab.profile").navigationBarTitleDisplayMode(.inline)
            .task(id: env.auth.user?.xp) { await loadBoard() }
        }
    }
}

struct BadgeGrid: View {
    let unlocked: Set<String>
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("profile.badges").pixelFont(11).foregroundStyle(PixelTheme.ink)
            PixelCard {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .top), count: 4), spacing: 14) {
                    ForEach(Badge.allCases, id: \.self) { b in
                        PixelBadgeView(badge: b, unlocked: unlocked.contains(b.rawValue), size: 52)
                    }
                }
            }
        }
    }
}

struct LeaderboardView: View {
    let state: LoadState<[NookUser]>
    let currentUID: String
    let retry: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("profile.leaderboard").pixelFont(11).foregroundStyle(PixelTheme.ink)
            switch state {
            case .idle, .loading: ProgressView().frame(maxWidth: .infinity)
            case .failed(let k): ErrorView(messageKey: k, retry: retry).frame(height: 260)
            case .empty: EmptyStateView().frame(height: 220)
            case .loaded(let list):
                PixelCard {
                    VStack(spacing: 10) {
                        ForEach(Array(list.enumerated()), id: \.element.id) { i, u in
                            HStack(spacing: 10) {
                                Text(verbatim: "#\(i + 1)").pixelFont(10).frame(width: 36, alignment: .leading)
                                    .foregroundStyle(i == 0 ? PixelTheme.orange : PixelTheme.ink)
                                PixelAvatarView(id: u.avatarId, size: 30)
                                Text(u.pseudo).pixelFont(10).lineLimit(1)
                                Spacer()
                                Text(verbatim: "\(u.xp) XP").pixelFont(9)
                            }
                            .padding(.vertical, 2)
                            .background(u.id == currentUID ? PixelTheme.accent.opacity(0.25) : .clear)
                        }
                    }
                }
            }
        }
    }
}
