import SwiftUI
import SweetUIFoundations

/// An educational strategy card, translated from shadcn's index-investing: a
/// title, a short description, an explanatory paragraph, and a link. shadcn
/// makes the lead phrase an inline anchor; SwiftUI has no inline link in a
/// flowing paragraph without a real URL, so this keeps the paragraph plain and
/// offers the link as a trailing registry link button. The copy names no brand.
public struct IndexInvesting: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("A steady strategy for building wealth over time.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("Investing a fixed amount on a fixed schedule smooths out the average cost of your holdings. When prices drop, your fixed amount buys more shares; when prices rise, it buys fewer. The result is a lower average cost per share than lump-sum investing during volatile periods.")
                    .font(.subheadline)

                Button("How it works") {}
                    .buttonStyle(.registryLink)
                    .controlSize(.small)
            }
        } label: {
            Text("Dollar-Cost Averaging")
        }
        .groupBoxStyle(.registryCard)
    }
}

#if DEBUG
#Preview("Index Investing") {
    ScrollView { IndexInvesting().padding() }
        .registryTheme(.indigo)
}

#Preview("Index Investing Dark") {
    ScrollView { IndexInvesting().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
