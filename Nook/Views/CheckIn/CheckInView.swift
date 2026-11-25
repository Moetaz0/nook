import SwiftUI

struct CheckInView: View {
    let spot: Spot
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var vm = CheckInViewModel()

    var body: some View {
        @Bindable var vm = self.vm
        ZStack {
            PixelBackground()
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("checkin.title").pixelFont(16)
                            Text(spot.name).font(.callout).opacity(0.7)
                        }
                        Spacer()
                        PixelMascotView(mood: .hop, size: 70)
                    }
                    Text("checkin.hint").pixelFont(9).opacity(0.7).frame(maxWidth: .infinity, alignment: .leading)
                    PixelCard {
                        VStack(spacing: 14) {
                            LevelPicker(title: "gauge.noise", icon: "speaker.wave.2.fill", value: $vm.noise, invert: true)
                            LevelPicker(title: "gauge.crowd", icon: "person.2.fill", value: $vm.crowd, invert: true)
                            LevelPicker(title: "gauge.wifi", icon: "wifi", value: $vm.wifi, invert: false)
                            LevelPicker(title: "gauge.outlets", icon: "powerplug.fill", value: $vm.outlets, invert: false)
                        }
                    }
                    PixelTextField(title: "checkin.price", text: $vm.price, error: vm.priceError, keyboard: .decimalPad)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("checkin.rating").pixelFont(9).opacity(0.7)
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { i in
                                Button { withAnimation(.bouncy) { vm.rating = i } } label: {
                                    Image(systemName: i <= vm.rating ? "star.fill" : "star").font(.title)
                                        .foregroundStyle(PixelTheme.orange).scaleEffect(i == vm.rating ? 1.25 : 1)
                                }
                            }
                        }
                        .sensoryFeedback(.selection, trigger: vm.rating)
                        if let e = vm.ratingError { Text(LocalizedStringKey(e)).pixelFont(8).foregroundStyle(.red) }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("checkin.comment").pixelFont(9).opacity(0.7)
                        TextEditor(text: $vm.comment).frame(height: 90).scrollContentBackground(.hidden).padding(8)
                            .pixelFrame(fill: PixelTheme.surface, border: vm.commentError == nil ? PixelTheme.ink : .red, shadow: false)
                        HStack {
                            if let e = vm.commentError { Text(LocalizedStringKey(e)).pixelFont(8).foregroundStyle(.red) }
                            Spacer()
                            Text("\(vm.comment.count)/200").pixelFont(8).foregroundStyle(vm.comment.count > 200 ? .red : PixelTheme.ink.opacity(0.6))
                        }
                    }
                    if let e = vm.error { Text(LocalizedStringKey(e)).pixelFont(9).foregroundStyle(.red) }
                    PixelButton("checkin.submit", isLoading: vm.isBusy) { Task { await vm.submit(spot: spot, env: env) } }
                    Button { dismiss() } label: { Text("checkin.cancel").pixelFont(9).underline() }
                }
                .foregroundStyle(PixelTheme.ink).padding(20)
            }
            .scrollDismissesKeyboard(.interactively)

            if let r = vm.result {
                XPGainOverlay(result: r) {
                    dismiss()
                    // Interstitielle : 1 fois toutes les 3 actions, jamais pour Nook+
                    Task {
                        try? await Task.sleep(for: .milliseconds(450))
                        env.ads.completeAction(isPlus: env.purchases.isPlus)
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: vm.result == nil)
    }
}

/// 5 cases pixel pour noter un critère (1...5). invert = vert à gauche (bruit/affluence faibles = bien)
struct LevelPicker: View {
    let title: LocalizedStringKey
    let icon: String
    @Binding var value: Int
    let invert: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label { Text(title) } icon: { Image(systemName: icon) }.pixelFont(9)
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { i in
                    let good = invert ? 1 - Double(i - 1) / 4 : Double(i - 1) / 4
                    Button { withAnimation(.snappy) { value = i } } label: {
                        Rectangle().fill(i <= value ? PixelTheme.quality(invert ? 1 - Double(value - 1) / 4 : Double(value - 1) / 4) : PixelTheme.ink.opacity(0.12))
                            .frame(height: 30)
                            .overlay { Text("\(i)").pixelFont(9).foregroundStyle(i <= value ? PixelTheme.midnight : PixelTheme.ink.opacity(0.5)) }
                            .overlay { Rectangle().stroke(PixelTheme.ink, lineWidth: i == value ? 3 : 0) }
                            .accessibilityLabel(Text("\(i)")).accessibilityValue(Text(good.formatted()))
                    }
                    .buttonStyle(.plain)
                }
            }
            .sensoryFeedback(.selection, trigger: value)
        }
    }
}

struct XPGainOverlay: View {
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
                    Text("checkin.done").pixelFont(13)
                    Text(verbatim: "+\(result.gained) XP").pixelFont(26).foregroundStyle(PixelTheme.green)
                        .scaleEffect(popped ? 1 : 0.2)
                    XPBarView(progress: progress)
                    if result.leveledUp {
                        VStack(spacing: 4) {
                            Text("checkin.levelup").pixelFont(11).foregroundStyle(PixelTheme.accent)
                            Label { Text(LocalizedStringKey(result.newLevel.titleKey)) } icon: { Image(systemName: result.newLevel.icon) }.pixelFont(11)
                        }.scaleEffect(popped ? 1 : 0)
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
            if result.leveledUp {
                withAnimation(.easeOut(duration: 0.8)) { progress = 1 }
                try? await Task.sleep(for: .milliseconds(900))
                progress = 0
                try? await Task.sleep(for: .milliseconds(100))
            }
            withAnimation(.easeOut(duration: 1.2)) { progress = UserLevel.progress(result.user.xp) }
        }
    }
}
