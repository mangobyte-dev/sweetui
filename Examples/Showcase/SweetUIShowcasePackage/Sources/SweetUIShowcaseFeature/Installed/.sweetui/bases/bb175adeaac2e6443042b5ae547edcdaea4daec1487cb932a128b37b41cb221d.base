import SwiftUI
import SweetUIFoundations

/// A display-only transaction row. Selection belongs to the containing block or app.
public struct TransactionRow: View {
    public enum Tone: String, Codable, Sendable {
        case neutral
        case positive
        case negative
    }

    private let title: Text
    private let subtitle: Text
    private let amount: Text
    private let systemImage: String
    private var tone: Tone = .neutral

    public init(
        title: Text,
        subtitle: Text,
        amount: Text,
        systemImage: String
    ) {
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.systemImage = systemImage
    }

    /// Sets the semantic tone. Defaults to neutral.
    public func registryTone(_ tone: Tone) -> Self {
        var copy = self
        copy.tone = tone
        return copy
    }

    public var body: some View {
        TransactionRowContent(
            title: title,
            subtitle: subtitle,
            amount: amount,
            systemImage: systemImage,
            tone: tone
        )
        .registryItem("transaction-row")
    }
}

private struct TransactionRowContent: View {
    @Environment(\.registryTheme) private var theme

    let title: Text
    let subtitle: Text
    let amount: Text
    let systemImage: String
    let tone: TransactionRow.Tone

    var body: some View {
        row.accessibilityValue(toneDescription ?? Text(verbatim: ""))
    }

    private var row: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: theme.metrics.standardSpacing) {
                TransactionIcon(systemImage: systemImage, tone: tone)
                TransactionLabels(title: title, subtitle: subtitle)
                Spacer(minLength: theme.metrics.compactSpacing)
                TransactionAmount(amount: amount, tone: tone)
            }

            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                HStack(spacing: theme.metrics.standardSpacing) {
                    TransactionIcon(systemImage: systemImage, tone: tone)
                    TransactionLabels(title: title, subtitle: subtitle)
                }
                TransactionAmount(amount: amount, tone: tone)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var toneDescription: Text? {
        switch tone {
        case .neutral:
            nil
        case .positive:
            Text("Positive amount")
        case .negative:
            Text("Negative amount")
        }
    }
}

private struct TransactionIcon: View {
    @Environment(\.registryTheme) private var theme
    @ScaledMetric(relativeTo: .body) private var diameter: CGFloat = 40

    let systemImage: String
    let tone: TransactionRow.Tone

    var body: some View {
        Image(systemName: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(toneColor)
            .frame(width: diameter, height: diameter)
            .background(toneColor.opacity(0.12), in: Circle())
            .accessibilityHidden(true)
    }

    private var toneColor: Color {
        color(for: tone, theme: theme)
    }
}

private struct TransactionLabels: View {
    @Environment(\.registryTheme) private var theme

    let title: Text
    let subtitle: Text

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing / 2) {
            title
                .font(.body.weight(.medium))
            subtitle
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TransactionAmount: View {
    @Environment(\.registryTheme) private var theme

    let amount: Text
    let tone: TransactionRow.Tone

    var body: some View {
        amount
            .font(.body.weight(.semibold))
            .monospacedDigit()
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(color(for: tone, theme: theme))
    }
}

private func color(for tone: TransactionRow.Tone, theme: RegistryTheme) -> Color {
    switch tone {
    case .neutral:
        .secondary
    case .positive:
        theme.positive
    case .negative:
        theme.negative
    }
}

private struct TransactionRowPreview: View {
    var body: some View {
        VStack(spacing: 16) {
            TransactionRow(
                title: Text("Mishmash Bakery"),
                subtitle: Text("Today, 09:41"),
                amount: Text(-8.75, format: .currency(code: "KWD")),
                systemImage: "cup.and.saucer.fill"
            )
            .registryTone(.negative)
            TransactionRow(
                title: Text("Salary"),
                subtitle: Text("Yesterday"),
                amount: Text(2_450, format: .currency(code: "KWD")),
                systemImage: "building.columns.fill"
            )
            .registryTone(.positive)
            TransactionRow(
                title: Text("Pending transfer"),
                subtitle: Text("Yesterday"),
                amount: Text(120, format: .currency(code: "KWD")),
                systemImage: "arrow.left.arrow.right"
            )
        }
        .padding()
    }
}

#Preview("Transaction Row") {
    TransactionRowPreview()
}

#Preview("Transaction Row Dark") {
    TransactionRowPreview().preferredColorScheme(.dark)
}

#Preview("Transaction Row Accessibility Size") {
    TransactionRowPreview().dynamicTypeSize(.accessibility3)
}
