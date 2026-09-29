import SwiftUI
import SweetUIFoundations

/// Account access, translated from shadcn's account-access: an email field, a
/// current-password field with an inline reset link, a full-width update
/// action, and a muted danger-zone row. The text field and secure field wear
/// the registry input treatment, and the danger row is an ItemRow on the
/// content surface wrapped in a native button.
public struct AccountAccess: View {
    @Environment(\.registryTheme) private var theme
    @State private var email = "artist@studio.inc"
    @State private var password = ""

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Update your credentials or re-authenticate.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                FieldGroup {
                    Field("Email address") { _ in
                        TextField("you@studio.inc", text: $email)
                            .textFieldStyle(.registryInput)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .accessibilityLabel("Email address")
                    }

                    Field("Current password") { _ in
                        SecureField("Enter current password", text: $password)
                            .textFieldStyle(.registryInput)
                            .accessibilityLabel("Current password")
                    }

                    Button("Forgot password?") {}
                        .buttonStyle(.registryLink)
                        .controlSize(.small)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Button {
                } label: {
                    Label("Update security", systemImage: "lock.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.registry)

                dangerRow
            }
        } label: {
            Text("Account Access")
        }
        .groupBoxStyle(.registryCard)
    }

    private var dangerRow: some View {
        Button {
        } label: {
            ItemRow(
                title: Text("Danger zone"),
                description: Text("Archive account and remove catalog")
            ) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(theme.negative)
                    .accessibilityHidden(true)
            } accessory: {
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, theme.metrics.standardSpacing)
            .registrySurface()
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("Account Access") {
    ScrollView { AccountAccess().padding() }
        .registryTheme(.indigo)
}

#Preview("Account Access Dark") {
    ScrollView { AccountAccess().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
