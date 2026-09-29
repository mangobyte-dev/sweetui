import Charts
import SwiftUI
import SweetUIFoundations

/// A stock-performance card, translated from shadcn's stock-performance: a
/// ticker combobox over a six-month price chart. shadcn uses its combobox and
/// chart primitives; this keeps the registry Combobox in a Field for the
/// search-and-select, and a Swift Charts AreaMark plus LineMark styled with
/// registryChart(), so the chart follows the theme tint. Choosing a ticker
/// swaps the series. Tickers are invented, so the card names no brand.
public struct StockPerformance: View {
    @Environment(\.registryTheme) private var theme
    @State private var ticker: String? = "hrb"

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("6-month price history.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                FieldGroup {
                    Field("Ticker") { _ in
                        Combobox(
                            selection: $ticker,
                            options: Self.options,
                            prompt: "Search ticker",
                            emptyDescription: Text("Try another symbol.")
                        )
                    }
                }

                Divider().registrySeparator()

                chart
            }
        } label: {
            Text("Stock Performance")
        }
        .groupBoxStyle(.registryCard)
    }

    private var chart: some View {
        Chart(pricePoints) { point in
            AreaMark(
                x: .value("Month", point.month),
                y: .value("Price", point.price)
            )
            .foregroundStyle(TintShapeStyle().opacity(0.2))
            .interpolationMethod(.monotone)

            LineMark(
                x: .value("Month", point.month),
                y: .value("Price", point.price)
            )
            .foregroundStyle(TintShapeStyle())
            .interpolationMethod(.monotone)
        }
        .registryChart()
        .frame(height: 200)
        .accessibilityLabel("Six-month price history for \(selectedTitle)")
    }

    private var pricePoints: [PricePoint] {
        Self.series[ticker ?? ""] ?? Self.defaultSeries
    }

    private var selectedTitle: String {
        Self.options.first { $0.id == ticker }?.title ?? "the selected ticker"
    }

    private struct PricePoint: Identifiable {
        let id: String
        let month: String
        let price: Double
    }

    private static let options: [ComboboxOption<String>] = [
        ComboboxOption(id: "hrb", title: "HRB"),
        ComboboxOption(id: "mdx", title: "MDX"),
        ComboboxOption(id: "cbt", title: "CBT"),
        ComboboxOption(id: "vlm", title: "VLM"),
        ComboboxOption(id: "orn", title: "ORN"),
        ComboboxOption(id: "alt", title: "ALT"),
    ]

    private static func makeSeries(_ prices: [Double]) -> [PricePoint] {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
        return zip(months, prices).map { PricePoint(id: $0.0, month: $0.0, price: $0.1) }
    }

    private static let series: [String: [PricePoint]] = [
        "hrb": makeSeries([412, 438, 395, 450, 420, 462]),
        "cbt": makeSeries([185, 210, 172, 198, 178, 215]),
    ]

    private static let defaultSeries: [PricePoint] = makeSeries([100, 118, 95, 125, 108, 130])
}

#if DEBUG
#Preview("Stock Performance") {
    ScrollView { StockPerformance().padding() }
        .registryTheme(.indigo)
}

#Preview("Stock Performance Dark") {
    ScrollView { StockPerformance().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
