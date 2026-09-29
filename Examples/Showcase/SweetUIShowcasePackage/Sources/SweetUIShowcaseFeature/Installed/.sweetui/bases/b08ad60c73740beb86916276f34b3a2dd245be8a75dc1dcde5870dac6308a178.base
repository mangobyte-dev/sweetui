import SwiftUI
import SweetUIFoundations

/// A developer profile form, translated from shadcn's github-profile and kept
/// generic: a name field on the registry input treatment, a public email
/// chosen with a native menu Picker, and a bio on the registry text-area
/// treatment, each with guidance, plus a save action.
public struct DeveloperProfile: View {
    @Environment(\.registryTheme) private var theme
    @State private var name = ""
    @State private var email = "you@example.com"
    @State private var bio = "Building developer tools and design systems."

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Manage your profile information.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                FieldGroup {
                    nameField
                    emailField
                    bioField
                }

                Button("Save profile") {}
                    .buttonStyle(.registry)
                    .frame(maxWidth: .infinity)
            }
        } label: {
            Text("Profile")
        }
        .groupBoxStyle(.registryCard)
    }

    private var nameField: some View {
        Field(
            "Name",
            description: "Your name may appear around the app where you contribute or are mentioned. You can remove it at any time."
        ) { isInvalid in
            TextField("Your name", text: $name)
                .textFieldStyle(RegistryInputStyle(isInvalid: isInvalid))
                .accessibilityLabel("Name")
        }
    }

    private var emailField: some View {
        Field(
            "Public email",
            description: "You can manage verified email addresses in your account settings."
        ) { _ in
            Picker("Public email", selection: $email) {
                Text("you@example.com").tag("you@example.com")
                Text("you@work.example.com").tag("you@work.example.com")
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Public email")
        }
    }

    private var bioField: some View {
        Field(
            "Bio",
            description: "You can @mention other people and teams to link to them."
        ) { _ in
            TextEditor(text: $bio)
                .registryTextArea(accessibilityLabel: Text("Bio"))
        }
    }
}

#if DEBUG
#Preview("Developer Profile") {
    ScrollView { DeveloperProfile().padding() }
        .registryTheme(.indigo)
}

#Preview("Developer Profile Dark") {
    ScrollView { DeveloperProfile().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
