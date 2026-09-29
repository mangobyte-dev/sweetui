import SwiftUI
import SweetUIFoundations

/// A device-pairing card, translated from shadcn's qr-connect: a scannable
/// code, a title, a description, and a confirm action. shadcn renders a real
/// QR image; this draws a deterministic illustrative module grid with `Canvas`
/// from a fixed bit pattern, black on white, so it needs no image, no
/// CoreImage, and no randomness, and it is labeled as a placeholder. The app
/// name is invented, so the card names no brand.
public struct QrConnect: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(spacing: theme.metrics.standardSpacing) {
                code

                VStack(spacing: theme.metrics.compactSpacing / 2) {
                    Text("Scan to connect your mobile device")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("Open the Vaultline app and scan this code to link your device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button { } label: {
                    Text("Got it").frame(maxWidth: .infinity)
                }
                .buttonStyle(.registrySecondary)
            }
            .frame(maxWidth: .infinity)
        } label: {
            Text("Connect Device")
        }
        .groupBoxStyle(.registryCard)
    }

    private var code: some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)

        return Canvas { context, size in
            let count = Self.modules.count
            let cell = size.width / CGFloat(count)
            for row in 0..<count {
                for column in 0..<count where Self.modules[row][column] {
                    let rect = CGRect(
                        x: CGFloat(column) * cell,
                        y: CGFloat(row) * cell,
                        width: cell,
                        height: cell
                    )
                    context.fill(Path(rect), with: .color(.black))
                }
            }
        }
        .frame(width: 160, height: 160)
        .padding(theme.metrics.standardSpacing)
        .background(.white, in: shape)
        .overlay { shape.stroke(theme.border, lineWidth: theme.metrics.borderWidth) }
        .accessibilityElement()
        .accessibilityLabel("Placeholder QR code, shown for illustration only")
    }

    // A fixed, deterministic module grid: three finder patterns, timing lines,
    // and a data fill computed from a fixed formula, so the code is stable and
    // carries no real payload.
    private static let modules: [[Bool]] = makeModules()

    private static func makeModules() -> [[Bool]] {
        let count = 25
        var grid = Array(repeating: Array(repeating: false, count: count), count: count)

        func placeFinder(_ top: Int, _ left: Int) {
            for row in 0..<7 {
                for column in 0..<7 {
                    let onRing = row == 0 || row == 6 || column == 0 || column == 6
                    let inCenter = (2...4).contains(row) && (2...4).contains(column)
                    grid[top + row][left + column] = onRing || inCenter
                }
            }
        }
        placeFinder(0, 0)
        placeFinder(0, count - 7)
        placeFinder(count - 7, 0)

        for index in 8..<(count - 8) {
            grid[6][index] = index % 2 == 0
            grid[index][6] = index % 2 == 0
        }

        for row in 0..<count {
            for column in 0..<count {
                if isFinderRegion(row, column, count) { continue }
                if row == 6 || column == 6 { continue }
                grid[row][column] = ((row * 73 + column * 149 + 17) % 5) < 2
            }
        }
        return grid
    }

    private static func isFinderRegion(_ row: Int, _ column: Int, _ count: Int) -> Bool {
        (row < 8 && column < 8)
            || (row < 8 && column >= count - 8)
            || (row >= count - 8 && column < 8)
    }
}

#if DEBUG
#Preview("QR Connect") {
    ScrollView { QrConnect().padding() }
        .registryTheme(.indigo)
}

#Preview("QR Connect Dark") {
    ScrollView { QrConnect().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
