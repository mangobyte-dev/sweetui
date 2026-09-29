import SwiftUI
import SweetUIFoundations

/// A privacy setting, translated from shadcn's contributions-activity: a
/// checkbox with a title and a description, and a save action. The checkbox is
/// a native Toggle wearing the registry checkbox style, so it reports as a
/// switch to VoiceOver with the whole label spoken once.
public struct ContributionsActivity: View {
    @Environment(\.registryTheme) private var theme
    @State private var isPrivate = false

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Manage your contributions and activity visibility.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Toggle(isOn: $isPrivate) {
                    VStack(alignment: .leading, spacing: theme.metrics.compactSpacing / 2) {
                        Text("Make profile private and hide activity")
                        Text("Hides your contributions and activity from your profile and from social features like followers, stars, feeds, and releases.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.registryCheckbox)

                Button("Save changes") {}
                    .buttonStyle(.registry)
                    .frame(maxWidth: .infinity)
            }
        } label: {
            Text("Contributions & Activity")
        }
        .groupBoxStyle(.registryCard)
    }
}

#if DEBUG
#Preview("Contributions Activity") {
    ScrollView { ContributionsActivity().padding() }
        .registryTheme(.indigo)
}

#Preview("Contributions Activity Dark") {
    ScrollView { ContributionsActivity().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
