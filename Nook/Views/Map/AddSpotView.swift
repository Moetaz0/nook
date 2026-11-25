import SwiftUI
import MapKit

extension Validators {
    static func spotName(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return "err.spotname.required" }
        return (3...40).contains(t.count) ? nil : "err.spotname.length"
    }
    static func hours(_ s: String) -> String? { s.count > 40 ? "err.hours.long" : nil }
}

extension XPService {
    /// +30 XP et badge Explorateur pour l'ajout d'un spot
    static func spotAdded(to user: NookUser) -> XPResult {
        var u = user
        let oldLevel = UserLevel.level(for: u.xp)
        u.xp += 30
        let newLevel = UserLevel.level(for: u.xp)
        var unlocked: [Badge] = []
        func unlock(_ b: Badge, _ cond: Bool) {
            if cond && !u.badges.contains(b.rawValue) { u.badges.append(b.rawValue); unlocked.append(b) }
        }
        unlock(.explorer, true)
        unlock(.habitue, newLevel.rawValue >= UserLevel.habitue.rawValue)
        unlock(.maire, newLevel == .maire)
        return XPResult(gained: 30, oldXP: user.xp, user: u, leveledUp: newLevel != oldLevel, newLevel: newLevel, newBadges: unlocked)
    }
}

/// Bouton "+" à placer dans une toolbar (Explorer, Carte)
struct AddSpotButton: View {
    @Environment(AppEnvironment.self) private var env
    @State private var show = false
    var body: some View {
        Button { show = true } label: {
            Image(systemName: "plus.square.fill").font(.title2).foregroundStyle(PixelTheme.accent)
        }
        .accessibilityLabel(Text("addspot.button"))
        .sheet(isPresented: $show) {
            AddSpotView(start: env.location.location?.coordinate ?? env.explorer.center?.coordinate ?? AppConfig.defaultCoordinate)
        }
    }
}

struct AddSpotView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type = SpotType.cafe.rawValue
    @State private var hours = ""
    @State private var coordinate: CLLocationCoordinate2D
    @State private var camera: MapCameraPosition
    @State private var submitted = false
    @State private var isBusy = false
    @State private var error: String?
    @State private var result: XPResult?

    init(start: CLLocationCoordinate2D) {
        _coordinate = State(initialValue: start)
        _camera = State(initialValue: .region(MKCoordinateRegion(
            center: start, span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008))))
    }

    private var spotType: SpotType { SpotType(rawValue: type) ?? .cafe }
    private var nameError: String? { Validators.live(name, submitted: submitted, Validators.spotName) }
    private var hoursError: String? { Validators.live(hours, submitted: submitted, Validators.hours) }

    private func submit() async {
        submitted = true
        guard Validators.spotName(name) == nil, Validators.hours(hours) == nil, let user = env.auth.user else { return }
        isBusy = true; error = nil; defer { isBusy = false }
        let spot = Spot(id: "user-" + String(UUID().uuidString.prefix(8)),
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines), type: spotType,
                        latitude: coordinate.latitude, longitude: coordinate.longitude,
                        opening: hours.isEmpty ? nil : hours)
        do {
            try await env.data.addSpot(spot, uid: user.id)
            env.explorer.add(spot)
            let r = XPService.spotAdded(to: user)
            try await env.data.updateUser(r.user)
            env.auth.update(r.user)
            result = r
        } catch { self.error = AppError.key(for: error) }
    }

    var body: some View {
        ZStack {
            PixelBackground()
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text("addspot.title").pixelFont(16)
                        Spacer()
                        PixelMascotView(mood: .hop, size: 70)
                    }
                    PixelTextField(title: "addspot.name", text: $name, error: nameError)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("addspot.type").pixelFont(9).opacity(0.7)
                        PixelSegmented(options: SpotType.allCases.map { (value: $0.rawValue, title: LocalizedStringKey($0.titleKey)) },
                                       selection: $type)
                    }
                    PixelTextField(title: "addspot.hours", text: $hours, error: hoursError)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("addspot.location").pixelFont(9).opacity(0.7)
                        MapReader { proxy in
                            Map(position: $camera) {
                                UserAnnotation()
                                Annotation("", coordinate: coordinate, anchor: .bottom) { PixelPin(type: spotType, selected: true) }
                            }
                            .onTapGesture { p in
                                if let c = proxy.convert(p, from: .local) { coordinate = c }
                            }
                        }
                        .frame(height: 240)
                        .clipShape(PixelRect())
                        .overlay { PixelRect().stroke(PixelTheme.ink, lineWidth: 4) }
                        .sensoryFeedback(.impact, trigger: coordinate.latitude)
                        Text("addspot.tap").font(.caption).opacity(0.7)
                    }
                    if let e = error { Text(LocalizedStringKey(e)).pixelFont(9).foregroundStyle(.red) }
                    PixelButton("addspot.submit", isLoading: isBusy) { Task { await submit() } }
                    Button { dismiss() } label: { Text("checkin.cancel").pixelFont(9).underline() }
                }
                .foregroundStyle(PixelTheme.ink).padding(20)
            }
            .scrollDismissesKeyboard(.interactively)

            if let r = result {
                SpotAddedOverlay(result: r) {
                    dismiss()
                    Task {
                        try? await Task.sleep(for: .milliseconds(450))
                        env.ads.completeAction(isPlus: env.purchases.isPlus)
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: result == nil)
    }
}

struct SpotAddedOverlay: View {
    let result: XPResult
    let onClose: () -> Void
    @State private var progress: Double
    @State private var popped = false

    init(result: XPResult, onClose: @escaping () -> Void) {
        self.result = result; self.onClose = onClose
        _progress = State(initialValue: UserLevel.progress(result.oldXP))
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            PixelCard {
                VStack(spacing: 14) {
                    PixelMascotView(mood: .hop, size: 110)
                    Text("addspot.success").pixelFont(13)
                    Text(verbatim: "+\(result.gained) XP").pixelFont(26).foregroundStyle(PixelTheme.green).scaleEffect(popped ? 1 : 0.2)
                    XPBarView(progress: progress)
                    if result.leveledUp {
                        Label { Text(LocalizedStringKey(result.newLevel.titleKey)) } icon: { Image(systemName: result.newLevel.icon) }
                            .pixelFont(11).scaleEffect(popped ? 1 : 0)
                    }
                    if !result.newBadges.isEmpty {
                        Text("checkin.badge").pixelFont(9)
                        HStack(spacing: 12) {
                            ForEach(result.newBadges, id: \.self) { b in
                                PixelBadgeView(badge: b, size: 60).scaleEffect(popped ? 1 : 0)
                                    .animation(.bouncy(duration: 0.6).delay(0.6), value: popped)
                            }
                        }
                    }
                    PixelButton("checkin.close", action: onClose)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(24)
            PixelConfettiView()
        }
        .task {
            withAnimation(.bouncy) { popped = true }
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.easeOut(duration: 1.2)) { progress = result.leveledUp ? 1 : UserLevel.progress(result.user.xp) }
        }
    }		
}
