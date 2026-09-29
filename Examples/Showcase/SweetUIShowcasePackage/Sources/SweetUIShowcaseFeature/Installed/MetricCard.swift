import Foundation
import SwiftUI
import SweetUIFoundations

/// A compact product metric that leaves formatting and business meaning to its caller.
public struct MetricCard: View {
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
        MetricCardContent(
            title: title,
            value: value,
            detail: detail,
            systemImage: systemImage
        )
        .registryItem("metric-card")
    }
}

private struct MetricCardContent: View {
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
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.metrics.standardSpacing)
        .registrySurface()
        .accessibilityElement(children: .combine)
    }
}

private struct MetricCardPreview: View {
    var body: some View {
        VStack(spacing: 16) {
            MetricCard(
                "Available balance",
                value: Text(12_480.32, format: .currency(code: "USD")),
                detail: Text("Up 8.2% this month"),
                systemImage: "creditcard.fill"
            )
            MetricCard(
                "Monthly change",
                value: Text(0.082, format: .percent.precision(.fractionLength(1))),
                systemImage: "chart.line.uptrend.xyaxis"
            )
        }
        .padding()
    }
}

#Preview("Metric Card") {
    MetricCardPreview()
}

#Preview("Metric Card Dark") {
    MetricCardPreview().preferredColorScheme(.dark)
}

#Preview("Metric Card Accessibility Size") {
    MetricCardPreview().dynamicTypeSize(.accessibility3)
}
