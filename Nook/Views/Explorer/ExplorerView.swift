import SwiftUI

struct ExplorerView: View {
    @Environment(AppEnvironment.self) private var env

    private func reload() async {
        env.location.start()
        await env.explorer.load(location: env.location.location)
    }

    var body: some View {
        @Bindable var vm = env.explorer
        NavigationStack {
            VStack(spacing: 0) {
                FilterBar(selected: $vm.filters)
                Group {
                    switch vm.state {
                    case .idle, .loading: LoadingView()
                    case .failed(let key): ErrorView(messageKey: key) { Task { await reload() } }
                    case .empty: EmptyStateView()
                    case .loaded:
                        if vm.filtered.isEmpty { EmptyStateView() } else {
                            ScrollView {
                                LazyVStack(spacing: 14) {
                                    ForEach(vm.filtered) { s in
                                        NavigationLink(value: s) { SpotRow(spot: s, distance: s.distance(from: vm.center)) }
                                            .buttonStyle(.plain)
                                    }
                                }.padding()
                            }
                            .refreshable { await reload() }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .background(PixelBackground())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !env.purchases.isPlus {
                    AdBannerView().frame(maxWidth: .infinity).padding(.vertical, 4).background(PixelTheme.surface)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) { Text(verbatim: "NOOK").pixelFont(16).foregroundStyle(PixelTheme.accent) }
                ToolbarItem(placement: .topBarTrailing) { AddSpotButton() }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Spot.self) { SpotDetailView(spot: $0) }
        }
        .task {
            env.location.start()
            try? await Task.sleep(for: .milliseconds(800))   // laisse le temps à la 1re position d'arriver
            await env.explorer.loadIfNeeded(location: env.location.location)
        }
        .onChange(of: env.location.location) { _, l in
            if let l { Task { await env.explorer.locationUpdated(l) } }
        }
    }
}

struct FilterBar: View {
    @Binding var selected: Set<SpotFilter>
    var body: some View {
        HStack(spacing: 8) {
            ForEach(SpotFilter.allCases) { f in
                let on = selected.contains(f)
                Button {
                    withAnimation(.snappy) { if on { selected.remove(f) } else { selected.insert(f) } }
                } label: {
                    Label { Text(LocalizedStringKey(f.titleKey)) } icon: { Image(systemName: f.icon) }
                        .pixelFont(8).lineLimit(1).minimumScaleFactor(0.7)
                        .foregroundStyle(on ? PixelTheme.midnight : PixelTheme.ink)
                        .padding(.vertical, 10).frame(maxWidth: .infinity)
                        .pixelFrame(fill: on ? PixelTheme.accent : PixelTheme.surface, shadow: false)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: on)
            }
        }
        .padding(.horizontal).padding(.vertical, 10)
    }
}

struct SpotRow: View {
    let spot: Spot
    let distance: Double?

    private func fmt(_ d: Double) -> String { d < 1000 ? "\(Int(d)) m" : String(format: "%.1f km", d / 1000) }

    var body: some View {
        PixelCard {
            HStack(spacing: 12) {
                Image(systemName: spot.type.icon).font(.title2).frame(width: 46, height: 46)
                    .background(PixelTheme.accent.opacity(0.3))
                VStack(alignment: .leading, spacing: 6) {
                    Text(spot.name).pixelFont(11).lineLimit(1)
                    HStack(spacing: 8) {
                        Text(LocalizedStringKey(spot.type.titleKey))
                        if let distance { Text("· " + fmt(distance)) }
                    }.font(.caption).opacity(0.7)
                    HStack(spacing: 6) {
                        MiniStat(icon: "speaker.slash.fill", good: 1 - spot.live.noise)
                        MiniStat(icon: "person.2.fill", good: 1 - spot.live.crowd)
                        MiniStat(icon: "wifi", good: spot.live.wifi)
                        MiniStat(icon: "powerplug.fill", good: spot.live.outlets)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.forward")
            }
        }
    }
}

struct MiniStat: View {
    let icon: String
    let good: Double
    var body: some View {
        Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundStyle(PixelTheme.midnight)
            .frame(width: 26, height: 22).background(PixelTheme.quality(good))
    }
}
