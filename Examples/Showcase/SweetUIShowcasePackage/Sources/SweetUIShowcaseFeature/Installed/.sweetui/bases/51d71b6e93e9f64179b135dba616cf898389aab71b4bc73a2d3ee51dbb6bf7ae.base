import SwiftUI
import SweetUIFoundations

/// Report a bug, translated from shadcn's report-bug: a title field, a severity
/// and component select shown side by side, a steps-to-reproduce text area, and
/// attach and submit actions. The inputs wear the registry input, select, and
/// text-area treatments while the native controls stay visible at the call
/// site.
public struct ReportBug: View {
    @Environment(\.registryTheme) private var theme
    @State private var title = ""
    @State private var severity = "medium"
    @State private var component = "dashboard"
    @State private var steps = ""

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Help us fix issues faster.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                FieldGroup {
                    Field("Title") { _ in
                        TextField("Brief description of the issue", text: $title)
                            .textFieldStyle(.registryInput)
                            .accessibilityLabel("Title")
                    }

                    HStack(alignment: .top, spacing: theme.metrics.standardSpacing) {
                        Field("Severity") { _ in
                            Picker("Severity", selection: $severity) {
                                Text("Critical").tag("critical")
                                Text("High").tag("high")
                                Text("Medium").tag("medium")
                                Text("Low").tag("low")
                            }
                            .registrySelect()
                            .accessibilityLabel("Severity")
                        }

                        Field("Component") { _ in
                            Picker("Component", selection: $component) {
                                Text("Dashboard").tag("dashboard")
                                Text("Auth").tag("auth")
                                Text("API").tag("api")
                                Text("Billing").tag("billing")
                            }
                            .registrySelect()
                            .accessibilityLabel("Component")
                        }
                    }

                    Field("Steps to reproduce") { _ in
                        TextEditor(text: $steps)
                            .registryTextArea(accessibilityLabel: Text("Steps to reproduce"), minimumHeight: 96)
                    }
                }

                HStack(spacing: theme.metrics.compactSpacing) {
                    Spacer()
                    Button("Attach File") {}
                        .buttonStyle(.registryOutline)
                    Button("Submit Bug") {}
                        .buttonStyle(.registry)
                }
            }
        } label: {
            Text("Report Bug")
        }
        .groupBoxStyle(.registryCard)
    }
}

#if DEBUG
#Preview("Report Bug") {
    ScrollView { ReportBug().padding() }
        .registryTheme(.indigo)
}

#Preview("Report Bug Dark") {
    ScrollView { ReportBug().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
