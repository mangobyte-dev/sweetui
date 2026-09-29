import SwiftUI
import SweetUIFoundations

/// A smart-lock camera tile, translated from shadcn's front-door: a title with
/// a locked-status accessory, a device subtitle, and a 16:9 camera view with a
/// live badge. shadcn fills the view with a diagonal-stripe placeholder; this
/// draws the stripes deterministically with `Canvas` on the content surface, so
/// the tile needs no image. The device name is invented, so it names no brand.
public struct FrontDoor: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Sentinel Smart Lock")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                cameraView
            }
        } label: {
            HStack {
                Text("Front Door")
                Spacer()
                Label("Locked", systemImage: "lock.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .groupBoxStyle(.registryCard)
    }

    private var cameraView: some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)

        return shape
            .fill(theme.surface)
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .overlay {
                Canvas { context, size in
                    var offset = -size.height
                    while offset < size.width {
                        var path = Path()
                        path.move(to: CGPoint(x: offset, y: 0))
                        path.addLine(to: CGPoint(x: offset + size.height, y: size.height))
                        context.stroke(path, with: .color(theme.border), lineWidth: 1)
                        offset += 11
                    }
                }
                .clipShape(shape)
            }
            .overlay { shape.stroke(theme.border, lineWidth: theme.metrics.borderWidth) }
            .overlay(alignment: .topTrailing) {
                Text("Live")
                    .registryBadge(.destructive)
                    .padding(theme.metrics.compactSpacing)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Live front-door camera view")
    }
}

#if DEBUG
#Preview("Front Door") {
    ScrollView { FrontDoor().padding() }
        .registryTheme(.indigo)
}

#Preview("Front Door Dark") {
    ScrollView { FrontDoor().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
