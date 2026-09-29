import SwiftUI
import SweetUIFoundations

/// A holdings catalog, translated from shadcn's release-catalog: a search
/// input group and a filter group over a list of holdings, each with a ticker
/// monogram, a share count and added date, a type badge, and a value. shadcn
/// lays search and filters in one header row; on a compact card width they
/// stack. The filter group is a native ControlGroup of toggles wearing the
/// registry toggle-group treatment. Fund names and tickers are invented, so the
/// card names no brand; amounts and dates are formatted at the call site.
public struct ReleaseCatalog: View {
    @Environment(\.registryTheme) private var theme
    @State private var query = ""
    @State private var showStocks = false
    @State private var showETFs = true
    @State private var showREITs = false

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                InputGroup {
                    Image(systemName: "magnifyingglass")
                        .accessibilityHidden(true)
                } content: {
                    TextField("Search holdings or tickers", text: $query)
                        .accessibilityLabel("Search holdings or tickers")
                }

                ControlGroup {
                    Toggle("Stocks", isOn: $showStocks)
                    Toggle("ETFs", isOn: $showETFs)
                    Toggle("REITs", isOn: $showREITs)
                }
                .registryToggleGroup(.outline)

                holdingsList
            }
        } label: {
            Text("Holdings")
        }
        .groupBoxStyle(.registryCard)
    }

    private var holdingsList: some View {
        VStack(spacing: 0) {
            ForEach(Self.holdings) { holding in
                HoldingRow(holding: holding)
                if holding.id != Self.holdings.last?.id {
                    Divider().registrySeparator()
                }
            }
        }
        .padding(.horizontal, theme.metrics.standardSpacing)
        .registrySurface()
    }

    private struct HoldingRow: View {
        @Environment(\.registryTheme) private var theme
        let holding: Holding

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: theme.metrics.compactRadius, style: .continuous)

            ItemRow(
                title: Text(holding.name),
                description: Text("\(holding.shares, format: .number) shares · added \(holding.added, format: .dateTime.month(.abbreviated).year())")
            ) {
                Text(holding.ticker)
                    .font(.caption.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(theme.surface, in: shape)
                    .overlay { shape.stroke(theme.border, lineWidth: theme.metrics.borderWidth) }
                    .accessibilityHidden(true)
            } accessory: {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(holding.type)
                        .registryBadge(.outline)
                    Text(holding.value, format: .currency(code: "USD"))
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                }
            }
            .padding(.vertical, theme.metrics.compactSpacing)
        }
    }

    private struct Holding: Identifiable {
        let id: String
        let ticker: String
        let name: String
        let type: LocalizedStringResource
        let shares: Int
        let added: Date
        let value: Double
    }

    private static func month(_ month: Int, _ year: Int) -> Date {
        DateComponents(calendar: .current, year: year, month: month, day: 1).date ?? .now
    }

    private static let holdings: [Holding] = [
        Holding(id: "harborline", ticker: "HRB", name: "Harborline Dividend Fund", type: "ETF", shares: 450, added: month(3, 2022), value: 26_033.79),
        Holding(id: "meridian", ticker: "MDX", name: "Meridian Index 500", type: "ETF", shares: 112, added: month(1, 2021), value: 48_230.40),
        Holding(id: "cobalt", ticker: "CBT", name: "Cobalt Technologies", type: "Stock", shares: 85, added: month(11, 2020), value: 18_488.90),
        Holding(id: "vellum", ticker: "VLM", name: "Vellum Property Trust", type: "REIT", shares: 320, added: month(6, 2023), value: 15_136.59),
    ]
}

#if DEBUG
#Preview("Release Catalog") {
    ScrollView { ReleaseCatalog().padding() }
        .registryTheme(.indigo)
}

#Preview("Release Catalog Dark") {
    ScrollView { ReleaseCatalog().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
