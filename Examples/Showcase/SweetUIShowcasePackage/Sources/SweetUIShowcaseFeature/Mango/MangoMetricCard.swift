import Foundation
import SwiftUI
import SweetUIFoundations

// MangoMetricCard is an owned copy of the registry `metric-card` item, version 0.2.1,
// copied from Installed/MetricCard.swift for the MANGO sample design system.
// MANGO edits, one per line:
// 1. Renamed MetricCard to MangoMetricCard (and its private content and preview types).
// 2. Added .monospacedDigit() to the detail so a changing detail keeps tabular figures;
//    the value already carried .monospacedDigit() in 0.2.1.
// 3. The previews apply .registryTheme(.mango) and .fontDesign(.rounded) so they show
//    the MANGO look; their contexts (light, dark, accessibility size) are unchanged.

/// A compact product metric that leaves formatting and business meaning to its caller.
public struct MangoMetricCard: View {
    private let title: LocalizedStringResource
    private let value: Text
    private let detail: Text?
    private let systemImage: String

    public init(
        _ title: LocalizedStringResource,
        value: Text,
        detail: Text? = nil,
        systemImage: String
    ) {
        self.title = title
        self.value = value
        self.detail = detail
        self.systemImage = systemImage
    }

    public var body: some View {
        MangoMetricCardContent(
            title: title,
            value: value,
            detail: detail,
            systemImage: systemImage
        )
    }
}

private struct MangoMetricCardContent: View {
    @Environment(\.registryTheme) private var theme
    @ScaledMetric(relativeTo: .body) private var iconDiameter: CGFloat = 40

    let title: LocalizedStringResource
    let value: Text
    let detail: Text?
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            HStack(alignment: .center, spacing: theme.metrics.compactSpacing) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer(minLength: theme.metrics.compactSpacing)

                ZStack {
                    Circle()
                        .fill(.tint)
                        .opacity(0.12)
                    Image(systemName: systemImage)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
                .frame(width: iconDiameter, height: iconDiameter)
            }

            VStack(alignment: .leading, spacing: theme.metrics.compactSpacing / 2) {
                value
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()

                if let detail {
                    detail
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.metrics.standardSpacing)
        .registrySurface()
        .accessibilityElement(children: .combine)
    }
}

private struct MangoMetricCardPreview: View {
    var body: some View {
        VStack(spacing: 16) {
            MangoMetricCard(
                "Available balance",
                value: Text(12_480.32, format: .currency(code: "USD")),
                detail: Text("Up 8.2% this month"),
                systemImage: "creditcard.fill"
            )
            MangoMetricCard(
                "Monthly change",
                value: Text(0.082, format: .percent.precision(.fractionLength(1))),
                systemImage: "chart.line.uptrend.xyaxis"
            )
        }
        .padding()
        .registryTheme(.mango)
        .fontDesign(.rounded)
    }
}

#Preview("Mango Metric Card") {
    MangoMetricCardPreview()
}

#Preview("Mango Metric Card Dark") {
    MangoMetricCardPreview().preferredColorScheme(.dark)
}

#Preview("Mango Metric Card Accessibility Size") {
    MangoMetricCardPreview().dynamicTypeSize(.accessibility3)
}
