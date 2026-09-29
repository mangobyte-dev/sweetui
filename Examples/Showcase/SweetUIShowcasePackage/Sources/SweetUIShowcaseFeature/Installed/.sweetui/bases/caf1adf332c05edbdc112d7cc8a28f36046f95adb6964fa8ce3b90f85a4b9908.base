import SwiftUI
import SweetUIFoundations

/// A social-links form, translated from shadcn's social-links: labeled URL and
/// handle fields, each with a leading icon, over discard and save actions.
/// shadcn uses its field and input-group primitives; this keeps a native
/// TextField inside a registry InputGroup, with the icon as the leading
/// accessory, wrapped in a Field for the label. The field labels and handle are
/// generic, so the card names no third-party network.
public struct SocialLinks: View {
    @Environment(\.registryTheme) private var theme
    @State private var streamingProfile = ""
    @State private var publicHandle = "@synthetichorizons"
    @State private var audioProfile = ""
    @State private var website = ""

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                FieldGroup {
                    LinkField(label: "Streaming profile", systemImage: "music.note", placeholder: "Link to your streaming profile", text: $streamingProfile)
                    LinkField(label: "Public handle", systemImage: "at", placeholder: "Your public handle", text: $publicHandle)
                    LinkField(label: "Audio profile", systemImage: "waveform", placeholder: "Link to your audio profile", text: $audioProfile)
                    LinkField(label: "Website", systemImage: "globe", placeholder: "Your website URL", text: $website)
                }

                HStack(spacing: theme.metrics.compactSpacing) {
                    Spacer()
                    Button("Discard") {}
                        .buttonStyle(.registrySecondary)
                    Button("Save changes") {}
                        .buttonStyle(.registry)
                }
            }
        } label: {
            Text("Social Links")
        }
        .groupBoxStyle(.registryCard)
    }

    private struct LinkField: View {
        let label: LocalizedStringResource
        let systemImage: String
        let placeholder: LocalizedStringResource
        @Binding var text: String

        var body: some View {
            Field(label) { _ in
                InputGroup {
                    Image(systemName: systemImage)
                        .accessibilityHidden(true)
                } content: {
                    TextField(text: $text, prompt: Text(placeholder)) {
                        Text(label)
                    }
                    .accessibilityLabel(Text(label))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                }
            }
        }
    }
}

#if DEBUG
#Preview("Social Links") {
    ScrollView { SocialLinks().padding() }
        .registryTheme(.indigo)
}

#Preview("Social Links Dark") {
    ScrollView { SocialLinks().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
