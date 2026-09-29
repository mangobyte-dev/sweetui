import SwiftUI
import SweetUIFoundations

/// A claimable-balance card, translated from shadcn's claimable-balance: a
/// large balance, a pending-setup badge, a muted summary of royalties, fee,
/// and total on the content surface, and a distribution note. Every amount is
/// currency-formatted at the call site; the pending state reads as a badge
/// rather than a hardcoded color.
public struct ClaimableBalance: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text(0, format: .currency(code: "USD"))
                    .font(.system(size: 44, weight: .semibold))
                    .monospacedDigit()

                Label("Pending setup", systemImage: "clock")
                    .registryBadge(.outline)

                summary

                Text("Once your bank is connected, balances over \(10, format: .currency(code: "USD")) are automatically eligible for monthly distribution on the 15th.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Text("Claimable Balance")
        }
        .groupBoxStyle(.registryCard)
    }

    private var summary: some View {
        VStack(spacing: theme.metrics.compactSpacing) {
            row("Net royalties", amount: 0)
            row("Processing fee", amount: 0)
            Divider().registrySeparator()
            row("Total ready to claim", amount: 0, emphasized: true)
        }
        .padding(theme.metrics.standardSpacing)
        .registrySurface()
    }

    private func row(_ label: LocalizedStringResource, amount: Double, emphasized: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(amount, format: .currency(code: "USD"))
                .font(.subheadline.weight(emphasized ? .semibold : .medium))
                .monospacedDigit()
        }
    }
}

#if DEBUG
#Preview("Claimable Balance") {
    ScrollView { ClaimableBalance().padding() }
        .registryTheme(.indigo)
}

#Preview("Claimable Balance Dark") {
    ScrollView { ClaimableBalance().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
