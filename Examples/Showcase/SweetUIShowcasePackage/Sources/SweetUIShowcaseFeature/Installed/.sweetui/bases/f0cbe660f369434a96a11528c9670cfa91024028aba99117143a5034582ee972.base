import Foundation
import SwiftUI
import SweetUIFoundations

// MARK: - Per-row values rows communicate to their SettingsSection container

public extension ContainerValues {
    /// A caller-prepared secondary line ``SettingsSection`` renders under the row's control.
    @Entry var settingsRowDescription: Text? = nil

    /// A caller-prepared explanation ``SettingsSection`` renders under a disabled row's control.
    @Entry var settingsRowDisabledExplanation: Text? = nil
}

public extension View {
    /// Adds a secondary description line under this row inside ``SettingsSection``.
    ///
    /// Apply to a row's top-level view. A view that emits multiple subviews
    /// (`Group`, `ForEach`) attaches the value to each emitted subview.
    func settingsRowDescription(_ description: Text) -> some View {
        containerValue(\.settingsRowDescription, description)
    }

    /// Disables this row while keeping its chrome legible and the control announced
    /// as disabled, optionally rendering a visible explanation under the control.
    /// When `isDisabled` is false the explanation is cleared, so an enabled row with
    /// an explanation is unrepresentable.
    func settingsRowDisabled(
        _ isDisabled: Bool = true,
        explanation: Text? = nil
    ) -> some View {
        disabled(isDisabled)
            .containerValue(\.settingsRowDisabledExplanation, isDisabled ? explanation : nil)
    }
}

// MARK: - Section

/// A source-owned settings block that renders titled section structure, spacing,
/// separators, and accessibility around caller-provided native setting rows.
///
/// The caller keeps every native control visible in `content` and owns every value
/// through bindings. The block does not own a `ScrollView`, navigation container,
/// or maximum width. Toggles default to `.toggleStyle(.switch)` container-wide;
/// a row can restyle locally because the closer style wins.
public struct SettingsSection<Content: View>: View {
    @Environment(\.registryTheme) private var theme

    private let title: LocalizedStringResource
    private let footer: Text?
    private let content: Content

    public init(
        _ title: LocalizedStringResource,
        footer: Text? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                Group(subviews: content) { subviews in
                    ForEach(subviews) { subview in
                        SettingsSectionRow(subview: subview)

                        if subview.id != subviews.last?.id {
                            Divider().registrySeparator()
                        }
                    }
                }
            }
            .toggleStyle(.switch)
            .padding(.horizontal, theme.metrics.standardSpacing)
            .registrySurface()

            if let footer {
                footer
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .registryItem("settings-section")
    }
}

/// Private row chrome: renders one caller subview with its description and disabled
/// explanation kept outside the disabled subtree so they stay fully legible.
private struct SettingsSectionRow: View {
    @Environment(\.registryTheme) private var theme

    let subview: Subview

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing / 2) {
            subview
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: RegistryMetrics.minimumHitSize)

            if let description = subview.containerValues.settingsRowDescription {
                description
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let explanation = subview.containerValues.settingsRowDisabledExplanation {
                explanation
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, theme.metrics.standardSpacing)
    }
}

#if DEBUG
private struct SettingsSectionPreview: View {
    var marketingAllowed = false
    var disableAllRows = false

    @State private var alertsEnabled = true
    @State private var summaryEnabled = false
    @State private var marketingEnabled = false
    @State private var currency = "KWD"

    var body: some View {
        ScrollView {
            SettingsSection(
                "Notifications",
                footer: Text("Quiet hours apply to every channel.")
            ) {
                Toggle("Transaction alerts", isOn: $alertsEnabled)
                    .settingsRowDescription(
                        Text("A push notification for every card transaction.")
                    )
                    .settingsRowDisabled(disableAllRows)

                Toggle("Weekly summary", isOn: $summaryEnabled)
                    .settingsRowDisabled(disableAllRows)

                Toggle("Marketing messages", isOn: $marketingEnabled)
                    .settingsRowDisabled(
                        !marketingAllowed,
                        explanation: Text("Managed by your organization's privacy policy.")
                    )

                LabeledContent("Currency") {
                    Picker("Currency", selection: $currency) {
                        Text("Kuwaiti dinar").tag("KWD")
                        Text("US dollar").tag("USD")
                    }
                    .registrySelect()
                }
                .settingsRowDisabled(disableAllRows)

                Button(role: .destructive) {
                } label: {
                    Text("Sign out")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.registry)
                .settingsRowDisabled(disableAllRows)
            }
            .padding()
        }
    }
}

/// Proves subview flattening: `ForEach`-emitted rows each get their own chrome
/// and separators, and a container value applied to the `ForEach` reaches every
/// emitted subview.
private struct SettingsSectionGroupedRowsPreview: View {
    struct Channel: Identifiable {
        let id: String
        let name: String
        var enabled: Bool
    }

    @State private var channels = [
        Channel(id: "push", name: "Push", enabled: true),
        Channel(id: "email", name: "Email", enabled: false),
        Channel(id: "sms", name: "SMS", enabled: false)
    ]

    var body: some View {
        ScrollView {
            SettingsSection("Channels") {
                ForEach($channels) { $channel in
                    Toggle(channel.name, isOn: $channel.enabled)
                }
                .settingsRowDescription(Text("Delivered while quiet hours are off."))
            }
            .padding()
        }
    }
}

#Preview("Settings Section") {
    SettingsSectionPreview()
}

#Preview("Settings Section Disabled Rows") {
    SettingsSectionPreview(disableAllRows: true)
}

#Preview("Settings Section Grouped Rows") {
    SettingsSectionGroupedRowsPreview()
}

#Preview("Settings Section Dark") {
    SettingsSectionPreview()
        .preferredColorScheme(.dark)
}

#Preview("Settings Section Right to Left") {
    SettingsSectionPreview()
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Settings Section Accessibility Size") {
    SettingsSectionPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
