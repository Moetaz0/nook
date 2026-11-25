import SwiftUI
import SwiftData

struct SpotDetailView: View {
    let spot: Spot
    @Environment(AppEnvironment.self) private var env
    @Environment(\.modelContext) private var modelContext
    @Query private var favs: [FavoriteSpot]
    @State private var vm = SpotDetailViewModel()
    @State private var showCheckIn = false

    private var current: Spot { env.explorer.spot(id: spot.id) ?? spot }
    private var isFav: Bool { favs.contains { $0.id == spot.id } }

    private func toggleFavorite() {
        let was = isFav
        if let f = favs.first(where: { $0.id == spot.id }) { modelContext.delete(f) } else { modelContext.insert(FavoriteSpot(spot: spot)) }
        if let uid = env.auth.user?.id { Task { try? await env.data.setFavorite(uid: uid, spot: spot, isFavorite: !was) } }
    }

    var body: some View {
        let live = current.live
        ScrollView {
            VStack(spacing: 16) {
                PixelCard {
                    HStack(spacing: 12) {
                        Image(systemName: spot.type.icon).font(.title).frame(width: 52, height: 52).background(PixelTheme.accent.opacity(0.3))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(spot.name).pixelFont(13)
                            Text(LocalizedStringKey(spot.type.titleKey)).font(.caption).opacity(0.7)
                        }
                        Spacer()
                        Button { toggleFavorite() } label: {
                            Image(systemName: isFav ? "heart.fill" : "heart").font(.title2).foregroundStyle(PixelTheme.rose)
                                .symbolEffect(.bounce, value: isFav)
                        }
                    }
                }
                PixelCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("detail.live").pixelFont(11)
                        PixelGauge(icon: "speaker.wave.2.fill", label: "gauge.noise", value: live.noise, color: PixelTheme.quality(1 - live.noise))
                        PixelGauge(icon: "person.2.fill", label: "gauge.crowd", value: live.crowd, color: PixelTheme.quality(1 - live.crowd))
                        PixelGauge(icon: "wifi", label: "gauge.wifi", value: live.wifi, color: PixelTheme.quality(live.wifi))
                        PixelGauge(icon: "powerplug.fill", label: "gauge.outlets", value: live.outlets, color: PixelTheme.quality(live.outlets))
                        HStack {
                            Label { Text("gauge.coffee") } icon: { Image(systemName: "cup.and.saucer.fill") }.pixelFont(9)
                            Spacer()
                            Text(live.coffeePrice.map { String(format: "%.1f DT", $0) } ?? "—").pixelFont(11)
                        }
                        if live.count > 0 {
                            Text(live.updatedAt, style: .relative).font(.caption).opacity(0.6)
                        }
                    }
                }
                weatherCard
                PixelCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("detail.hours").pixelFont(11)
                        Text(spot.opening ?? L10n.t("detail.hours.unknown")).font(.system(.callout, design: .monospaced))
                    }
                }
                reviewsSection
                PixelButton("detail.checkin") { showCheckIn = true }
            }
            .padding()
        }
        .background(PixelBackground())
        .navigationTitle(spot.name).navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(spot: spot, data: env.data) }
        .sheet(isPresented: $showCheckIn, onDismiss: { Task { await vm.reloadReviews(spot: spot, data: env.data) } }) {
            CheckInView(spot: current)
        }
    }

    @ViewBuilder private var weatherCard: some View {
        PixelCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("detail.weather").pixelFont(11)
                switch vm.weather {
                case .idle, .loading: ProgressView().frame(maxWidth: .infinity)
                case .failed(let k): Text(LocalizedStringKey(k)).pixelFont(9).foregroundStyle(.red)
                case .empty: EmptyView()
                case .loaded(let w):
                    HStack(spacing: 14) {
                        Image(systemName: w.symbol).font(.system(size: 34)).symbolRenderingMode(.multicolor)
                        Text(String(format: "%.0f°C", w.current.temperature)).pixelFont(18)
                        Spacer()
                        Label { Text(LocalizedStringKey(w.terraceOK ? "weather.terrace" : "weather.indoor")) }
                            icon: { Image(systemName: w.terraceOK ? "tree.fill" : "house.fill") }
                            .pixelFont(9).foregroundStyle(w.terraceOK ? PixelTheme.green : PixelTheme.orange)
                    }
                }
            }
        }
    }

    @ViewBuilder private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("detail.reviews").pixelFont(11).foregroundStyle(PixelTheme.ink)
            switch vm.reviews {
            case .idle, .loading: ProgressView().frame(maxWidth: .infinity)
            case .failed(let k): ErrorView(messageKey: k) { Task { await vm.reloadReviews(spot: spot, data: env.data) } }.frame(height: 260)
            case .empty: Text("detail.noreviews").pixelFont(9).foregroundStyle(PixelTheme.ink.opacity(0.7)).padding(.vertical, 8)
            case .loaded(let list): ForEach(list) { ReviewRow(review: $0) }
            }
        }
    }
}

struct ReviewRow: View {
    let review: Review
    var body: some View {
        PixelCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(review.pseudo).pixelFont(10)
                    Spacer()
                    PixelStars(rating: review.rating)
                }
                Text(review.comment).font(.callout)
            }
        }
    }
}

struct PixelStars: View {
    let rating: Int
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { Image(systemName: $0 <= rating ? "star.fill" : "star").foregroundStyle(PixelTheme.orange).font(.caption) }
        }
    }
}
