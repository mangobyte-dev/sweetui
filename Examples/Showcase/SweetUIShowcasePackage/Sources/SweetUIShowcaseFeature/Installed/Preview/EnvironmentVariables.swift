import SwiftUI
import SweetUIFoundations

/// Environment variables, translated from shadcn's environment-variables card:
/// bordered monospaced rows for each key with a masked or visible value, and
/// edit and deploy actions.
public struct EnvironmentVariables: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Production · 8 variables")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                VStack(spacing: theme.metrics.compactSpacing) {
                    ForEach(variables) { variable in
                        row(variable)
                    }
                }

                HStack {
                    Button("Edit") {}
                        .buttonStyle(.registryOutline)
                    Spacer()
                    Button("Deploy") {}
                        .buttonStyle(.registry)
                }
            }
        } label: {
            Text("Environment Variables")
        }
        .groupBoxStyle(.registryCard)
    }

    private func row(_ variable: EnvVar) -> some View {
        HStack(spacing: theme.metrics.compactSpacing) {
            Text(variable.key)
                .fontWeight(.medium)
            Spacer(minLength: theme.metrics.compactSpacing)
            Text(variable.displayValue)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.caption)
        .monospaced()
        .padding(.horizontal, theme.metrics.controlHorizontalPadding)
        .padding(.vertical, theme.metrics.compactSpacing)
        .overlay {
            RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
                .stroke(theme.border, lineWidth: theme.metrics.borderWidth)
        }
    }

    private struct EnvVar: Identifiable {
        let id: String
        let key: String
        let value: String
        let masked: Bool
        var displayValue: String { masked ? "••••••••" : value }
    }

    private let variables: [EnvVar] = [
        EnvVar(id: "database", key: "DATABASE_URL", value: "postgres://db.example.com", masked: true),
        EnvVar(id: "api", key: "PUBLIC_API_URL", value: "https://api.example.com", masked: false),
        EnvVar(id: "secret", key: "API_SECRET_KEY", value: "svc_0000000000000000", masked: true),
    ]
}

#if DEBUG
#Preview("Environment Variables") {
    ScrollView { EnvironmentVariables().padding() }
        .registryTheme(.indigo)
}

#Preview("Environment Variables Dark") {
    ScrollView { EnvironmentVariables().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
