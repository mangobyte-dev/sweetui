import SwiftUI
import SweetUIFoundations

/// A dense sampler of controls, translated from shadcn's ui-elements: the
/// registry button, badge, item, field, input group, text area, checkbox, and
/// button-group treatments alongside native menu, picker, slider, switch, and
/// alert controls, all kept visible at the call site. Every control carries an
/// accessibility label and every decorative symbol is hidden.
public struct UIElements: View {
    @Environment(\.registryTheme) private var theme
    @State private var level = 500.0
    @State private var name = ""
    @State private var message = ""
    @State private var fruit = "apple"
    @State private var agree = true
    @State private var wifi = true
    @State private var isConfirmingReset = false

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                buttons
                twoFactorItem
                slider
                fields
                badges
                choices
                actions
            }
        } label: {
            Text("UI Elements")
        }
        .groupBoxStyle(.registryCard)
        .alert("Reset settings?", isPresented: $isConfirmingReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {}
        } message: {
            Text("This restores every control on this card to its default value.")
        }
    }

    private var buttons: some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            HStack(spacing: theme.metrics.compactSpacing) {
                Button("Button") {}
                    .buttonStyle(.registry)
                Button("Secondary") {}
                    .buttonStyle(.registrySecondary)
            }
            HStack(spacing: theme.metrics.compactSpacing) {
                Button("Outline") {}
                    .buttonStyle(.registryOutline)
                Button("Ghost") {}
                    .buttonStyle(.registryGhost)
            }
        }
    }

    private var twoFactorItem: some View {
        ItemRow(
            title: Text("Two-factor authentication"),
            description: Text("Verify via email or phone number.")
        ) {
            Image(systemName: "lock.shield")
                .font(.title3)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
        } accessory: {
            Button("Enable") {}
                .buttonStyle(.registrySecondary)
                .controlSize(.small)
        }
    }

    private var slider: some View {
        Slider(value: $level, in: 0...1000, step: 10)
            .accessibilityLabel("Level")
            .accessibilityValue(Text(level, format: .number))
    }

    private var fields: some View {
        FieldGroup {
            Field("Name") { _ in
                InputGroup {
                    TextField("Name", text: $name)
                        .accessibilityLabel("Name")
                } trailing: {
                    Image(systemName: "magnifyingglass")
                        .accessibilityHidden(true)
                }
            }

            Field("Message") { _ in
                TextEditor(text: $message)
                    .registryTextArea(accessibilityLabel: Text("Message"), minimumHeight: 80)
            }
        }
    }

    private var badges: some View {
        HStack(spacing: theme.metrics.compactSpacing) {
            Text("Badge").registryBadge()
            Text("Secondary").registryBadge(.secondary)
            Text("Outline").registryBadge(.outline)
        }
    }

    private var choices: some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            Picker("Fruit", selection: $fruit) {
                Text("Apple").tag("apple")
                Text("Banana").tag("banana")
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Fruit")

            Toggle(isOn: $agree) {
                Text("I agree to the terms")
            }
            .toggleStyle(.registryCheckbox)

            HStack {
                Text("Wi-Fi")
                Spacer()
                Toggle("Wi-Fi", isOn: $wifi)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .accessibilityLabel("Wi-Fi")
            }
        }
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            HStack(spacing: theme.metrics.compactSpacing) {
                Button("Reset settings") { isConfirmingReset = true }
                    .buttonStyle(.registryOutline)
                    .controlSize(.small)

                Spacer()

                Menu {
                    Button("Mute conversation") {}
                    Button("Mark as read") {}
                    Divider()
                    Button("Delete conversation", role: .destructive) {}
                } label: {
                    Label("More actions", systemImage: "ellipsis")
                }
                .accessibilityLabel("More actions")
            }

            ControlGroup {
                Button("Copy") {}
                Button("Move") {}
                Button("Archive") {}
            }
            .controlGroupStyle(.registryButtons)
        }
    }
}

#if DEBUG
#Preview("UI Elements") {
    ScrollView { UIElements().padding() }
        .registryTheme(.indigo)
}

#Preview("UI Elements Dark") {
    ScrollView { UIElements().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
