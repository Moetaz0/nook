import SwiftUI

struct PixelTextField: View {
    let title: LocalizedStringKey
    @Binding var text: String
    var secure = false
    var error: String? = nil
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).pixelFont(9).foregroundStyle(PixelTheme.ink.opacity(0.7))
            Group {
                if secure { SecureField("", text: $text) } else { TextField("", text: $text).keyboardType(keyboard) }
            }
            .textInputAutocapitalization(.never).autocorrectionDisabled()
            .pixelFont(12).foregroundStyle(PixelTheme.ink)
            .padding(12)
            .pixelFrame(fill: PixelTheme.surface, border: error == nil ? PixelTheme.ink : .red, shadow: false)
            if let error {
                Label { Text(LocalizedStringKey(error)) } icon: { Image(systemName: "exclamationmark.triangle.fill") }
                    .pixelFont(8).foregroundStyle(.red)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: error)
    }
}
