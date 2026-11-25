import SwiftUI

struct PixelButtonStyle: ButtonStyle {
    var color: Color = PixelTheme.accent
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .pixelFont(12)
            .multilineTextAlignment(.center)
            .foregroundStyle(PixelTheme.midnight)
            .padding(.vertical, 14).padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .pixelFrame(fill: color, border: PixelTheme.ink, shadow: !pressed)
            .offset(x: pressed ? 4 : 0, y: pressed ? 4 : 0)
            .padding(.trailing, 4).padding(.bottom, 4)
            .animation(.snappy(duration: 0.08), value: pressed)
            .sensoryFeedback(.impact(weight: .medium), trigger: pressed) { _, new in new }
    }
}

struct PixelButton: View {
    let title: LocalizedStringKey
    var color: Color
    var isLoading: Bool
    let action: () -> Void

    init(_ title: LocalizedStringKey, color: Color = PixelTheme.accent, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title; self.color = color; self.isLoading = isLoading; self.action = action
    }
    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isLoading ? 0 : 1)
                if isLoading { ProgressView().tint(PixelTheme.midnight) }
            }
        }
        .buttonStyle(PixelButtonStyle(color: color))
        .disabled(isLoading)
    }
}

/// Sélecteur segmenté pixel (thème, langue…)
struct PixelSegmented: View {
    let options: [(value: String, title: LocalizedStringKey)]
    @Binding var selection: String
    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.value) { o in
                Button { withAnimation(.snappy) { selection = o.value } } label: {
                    Text(o.title).pixelFont(10).padding(.vertical, 12).frame(maxWidth: .infinity)
                        .foregroundStyle(selection == o.value ? PixelTheme.midnight : PixelTheme.ink)
                        .pixelFrame(fill: selection == o.value ? PixelTheme.accent : PixelTheme.bg, shadow: false)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: selection)
            }
        }
    }
}
