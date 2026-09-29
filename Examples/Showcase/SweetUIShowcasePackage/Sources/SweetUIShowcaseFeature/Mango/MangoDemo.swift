import SwiftUI
import SweetUIFoundations

/// MANGO, MangoByte's sample design system, shown as one scene: rounded type,
/// strokeless surfaces, and a single accent spent on the primary action. It is
/// not a registry item; it is captured for the website's Themes page. The theme
/// and the font design are applied once here at the root, the set-up-once shape a
/// team copies for its own brand.
struct MangoDemo: View {
    var body: some View {
        MangoDemoContent()
            .registryTheme(.mango)
            .fontDesign(.rounded)
    }
}

private struct MangoDemoContent: View {
    @Environment(\.registryTheme) private var theme
    @State private var steps = 3
    @State private var dailyReminder = true
    @State private var shareProgress = false

    private var stepValue: Text {
        Text(steps * 1_000, format: .number)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.metrics.sectionSpacing) {
                header
                metric
                actions
                preferences
                footer
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            Text("MANGO")
                .font(.largeTitle.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            Text("A warm, generous, strokeless design system built on the registry.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // The value changes with a native Stepper so the metric card's tabular
    // digits stay column-aligned as the number grows and shrinks.
    private var metric: some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            MangoMetricCard(
                "Steps today",
                value: stepValue,
                detail: Text("Goal 10,000"),
                systemImage: "figure.walk"
            )
            Stepper(value: $steps, in: 0 ... 20) {
                Text("Adjust steps")
            }
        }
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: theme.metrics.standardSpacing) { actionButtons }
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) { actionButtons }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        Button("Continue") {}
            .buttonStyle(.mango)
        Button("Not now") {}
            .buttonStyle(.registryOutline)
    }

    // A strokeless surface (border opacity is zero in MANGO) holding native
    // Toggles in the installed checkbox style.
    private var preferences: some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            Toggle("Daily reminder", isOn: $dailyReminder)
                .toggleStyle(.registryCheckbox)
            Toggle("Share progress", isOn: $shareProgress)
                .toggleStyle(.registryCheckbox)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.metrics.standardSpacing)
        .registrySurface()
    }

    private var footer: some View {
        Text("Three choices: rounded type, strokeless surfaces, and one accent on the primary action.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

#Preview("MANGO") {
    MangoDemo()
}

#Preview("MANGO Dark") {
    MangoDemo()
        .preferredColorScheme(.dark)
}

#Preview("MANGO Right to Left") {
    MangoDemo()
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("MANGO Accessibility Size") {
    MangoDemo()
        .dynamicTypeSize(.accessibility3)
}
