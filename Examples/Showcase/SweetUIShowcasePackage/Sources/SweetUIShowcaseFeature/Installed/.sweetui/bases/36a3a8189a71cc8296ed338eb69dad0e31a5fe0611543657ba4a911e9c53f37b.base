import SwiftUI
import SweetUIFoundations

/// Appointment booking, translated from shadcn's book-appointment: a Field of
/// selectable time slots (single selection with registry button styles), an
/// inline notice, and a full-width booking action.
public struct BookAppointment: View {
    @Environment(\.registryTheme) private var theme
    @State private var selectedSlot = "9:00 AM"

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Dr. Sarah Chen · Cardiology")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                FieldGroup {
                    Field("Available on March 18, 2026") { _ in
                        slotGrid
                    }
                }

                InlineAlert("New patient?", message: Text("Please arrive 15 minutes early."))

                Button("Book appointment") {}
                    .buttonStyle(.registry)
                    .frame(maxWidth: .infinity)
            }
        } label: {
            Text("Book appointment")
        }
        .groupBoxStyle(.registryCard)
    }

    private var slotGrid: some View {
        Grid(horizontalSpacing: theme.metrics.compactSpacing, verticalSpacing: theme.metrics.compactSpacing) {
            ForEach(Array(stride(from: 0, to: slots.count, by: 2)), id: \.self) { start in
                GridRow {
                    ForEach(start..<min(start + 2, slots.count), id: \.self) { index in
                        slotButton(slots[index])
                    }
                }
            }
        }
    }

    private func slotButton(_ slot: String) -> some View {
        Button(slot) { selectedSlot = slot }
            .buttonStyle(RegistryButtonStyle(selectedSlot == slot ? .primary : .outline))
            .frame(maxWidth: .infinity)
    }

    private let slots = ["9:00 AM", "10:30 AM", "11:00 AM", "1:30 PM"]
}

#if DEBUG
#Preview("Book Appointment") {
    ScrollView { BookAppointment().padding() }
        .registryTheme(.indigo)
}

#Preview("Book Appointment Dark") {
    ScrollView { BookAppointment().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
