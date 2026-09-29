import SwiftUI
import SweetUIFoundations

/// A savings-goal form, translated from shadcn's new-milestone: a goal-name
/// field and a two-up row of target amount and target date, over two footer
/// actions. shadcn shows the amount and date as plain text inputs; this keeps
/// a currency-formatted numeric TextField and a native DatePicker, so both are
/// entered through native, format-respecting controls kept visible at the call
/// site.
public struct NewMilestone: View {
    @Environment(\.registryTheme) private var theme
    @State private var goalName = ""
    @State private var targetAmount: Double = 15_000
    @State private var targetDate = DateComponents(calendar: .current, year: 2026, month: 12, day: 1).date ?? .now

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Define your target and we'll help you pace your savings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                FieldGroup {
                    Field("Goal name") { _ in
                        TextField("New car, home deposit", text: $goalName)
                            .textFieldStyle(.registryInput)
                            .accessibilityLabel("Goal name")
                    }

                    HStack(alignment: .top, spacing: theme.metrics.standardSpacing) {
                        Field("Target amount") { _ in
                            TextField("Target amount", value: $targetAmount, format: .currency(code: "USD").precision(.fractionLength(0)))
                                .textFieldStyle(.registryInput)
                                .keyboardType(.decimalPad)
                                .accessibilityLabel("Target amount")
                        }

                        Field("Target date") { _ in
                            DatePicker("Target date", selection: $targetDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .accessibilityLabel("Target date")
                        }
                    }
                }

                VStack(spacing: theme.metrics.compactSpacing) {
                    Button { } label: {
                        Text("Create goal").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.registry)

                    Button { } label: {
                        Text("Cancel").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.registryOutline)
                }
            }
        } label: {
            Text("Set a New Milestone")
        }
        .groupBoxStyle(.registryCard)
    }
}

#if DEBUG
#Preview("New Milestone") {
    ScrollView { NewMilestone().padding() }
        .registryTheme(.indigo)
}

#Preview("New Milestone Dark") {
    ScrollView { NewMilestone().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
