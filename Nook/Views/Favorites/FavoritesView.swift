import SwiftUI
import SwiftData

/// Favoris stockés localement avec SwiftData (disponibles hors ligne)
struct FavoritesView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteSpot.addedAt, order: .reverse) private var favs: [FavoriteSpot]

    var body: some View {
        NavigationStack {
            Group {
                if favs.isEmpty {
                    EmptyStateView(messageKey: "state.fav.empty")
                } else {
                    List {
                        ForEach(favs) { f in
                            let s = env.explorer.spot(id: f.id) ?? f.spot
                            NavigationLink(value: s) { SpotRow(spot: s, distance: s.distance(from: env.location.location)) }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear).listRowSeparator(.hidden)
                        }
                        .onDelete { idx in
                            for i in idx {
                                let f = favs[i]
                                if let uid = env.auth.user?.id { Task { try? await env.data.setFavorite(uid: uid, spot: f.spot, isFavorite: false) } }
                                modelContext.delete(f)
                            }
                        }
                    }
                    .listStyle(.plain).scrollContentBackground(.hidden)
                }
            }
            .background(PixelBackground())
            .navigationTitle("tab.favorites").navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Spot.self) { SpotDetailView(spot: $0) }
        }
    }
}
