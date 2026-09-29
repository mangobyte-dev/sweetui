import SwiftUI
import SweetUIFoundations

/// A contributors wall, translated from shadcn's contributors card: a count
/// badge in the header, a wrap of initial avatars, and a link to the rest.
/// Avatars use initials, never fetched images; the rows are laid out without a
/// lazy container so the card measures correctly inside the wall.
public struct Contributors: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: theme.metrics.compactSpacing) {
                            ForEach(row, id: \.self) { username in
                                Avatar(initials: initials(username), accessibilityLabel: Text(username))
                                    .controlSize(.small)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }

                Button("Show all 810 contributors") {}
                    .buttonStyle(.registryLink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } label: {
            HStack {
                Text("Contributors")
                Text("312").registryBadge(.secondary)
            }
        }
        .groupBoxStyle(.registryCard)
    }

    private func initials(_ username: String) -> String {
        String(username.prefix(1)).uppercased()
    }

    private let perRow = 6

    private let usernames = [
        "riverbend", "cobaltlab", "sablewing", "meridianco", "quartzly", "harborline",
        "cedargrove", "vellum", "orbital", "pinnaclehq", "driftwood", "beaconbyte",
        "tidalforge", "ferrousfox", "solsticelab", "novaline",
    ]

    private var rows: [[String]] {
        stride(from: 0, to: usernames.count, by: perRow).map { start in
            Array(usernames[start..<min(start + perRow, usernames.count)])
        }
    }
}

#if DEBUG
#Preview("Contributors") {
    ScrollView { Contributors().padding() }
        .registryTheme(.indigo)
}

#Preview("Contributors Dark") {
    ScrollView { Contributors().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
