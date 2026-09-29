import SwiftUI
import SweetUIFoundations

/// A payments navigation card, translated from shadcn's payments: a breadcrumb
/// header with an account-options menu, over a list of navigable actions.
/// shadcn puts a dropdown-menu inside the breadcrumb trail; this keeps the
/// registry Breadcrumb for the trail and a native Menu beside it, and each
/// action is an ItemRow wrapped in a native Button on the content surface. The
/// copy is neutral banking, so the card names no brand.
public struct Payments: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                HStack {
                    Breadcrumb([
                        BreadcrumbItem(Text("Home"), action: {}),
                        BreadcrumbItem(Text("Payments")),
                    ])
                    Spacer()
                    Menu {
                        Button("Profile") {}
                        Button("Statements") {}
                        Button("Documents") {}
                    } label: {
                        Label("Account options", systemImage: "ellipsis")
                            .labelStyle(.iconOnly)
                    }
                }

                actions
            }
        }
        .groupBoxStyle(.registryCard)
    }

    private var actions: some View {
        VStack(spacing: 0) {
            ForEach(Self.paymentActions) { action in
                Button { } label: {
                    ItemRow(
                        title: Text(action.title),
                        description: Text(action.detail)
                    ) {
                        Image(systemName: action.systemImage)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                    } accessory: {
                        Image(systemName: "chevron.forward")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, theme.metrics.compactSpacing)
                }
                .buttonStyle(.plain)

                if action.id != Self.paymentActions.last?.id {
                    Divider().registrySeparator()
                }
            }
        }
        .padding(.horizontal, theme.metrics.standardSpacing)
        .registrySurface()
    }

    private struct PaymentAction: Identifiable {
        let id: String
        let title: String
        let detail: String
        let systemImage: String
    }

    private static let paymentActions: [PaymentAction] = [
        PaymentAction(id: "limit", title: "Change transfer limit", detail: "Adjust how much you can send from your balance.", systemImage: "gauge.medium"),
        PaymentAction(id: "scheduled", title: "Scheduled transfers", detail: "Set up a transfer to send at a later date.", systemImage: "calendar"),
        PaymentAction(id: "debits", title: "Direct debits", detail: "Set up and manage regular payments.", systemImage: "repeat"),
        PaymentAction(id: "recurring", title: "Recurring card payments", detail: "Manage your repeated card transactions.", systemImage: "creditcard"),
    ]
}

#if DEBUG
#Preview("Payments") {
    ScrollView { Payments().padding() }
        .registryTheme(.indigo)
}

#Preview("Payments Dark") {
    ScrollView { Payments().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
