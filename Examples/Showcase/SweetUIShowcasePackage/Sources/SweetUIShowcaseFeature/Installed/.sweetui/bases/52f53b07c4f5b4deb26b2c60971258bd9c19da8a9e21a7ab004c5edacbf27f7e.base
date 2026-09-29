import SwiftUI
import SweetUIFoundations

/// A circular identity image with initials or symbol fallback. The caller
/// prepares the image and the accessibility label; the avatar owns only its
/// shape, fallback, and size, which follows the environment control size and
/// scales with the text size.
public struct Avatar: View {
    @Environment(\.controlSize) private var controlSize
    @Environment(\.registryTheme) private var theme
    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    private let image: Image?
    private let initials: String?
    private let systemImage: String
    private let accessibilityLabel: Text

    /// - Parameters:
    ///   - image: The prepared image, or `nil` to show the fallback.
    ///   - initials: Shown when there is no image; use one or two characters.
    ///   - systemImage: Shown when there is neither image nor initials.
    ///   - accessibilityLabel: Required because a face or monogram cannot be read.
    public init(
        _ image: Image? = nil,
        initials: String? = nil,
        systemImage: String = "person.fill",
        accessibilityLabel: Text
    ) {
        self.image = image
        self.initials = initials
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(theme.surface)

            if let image {
                image
                    .resizable()
                    .scaledToFill()
            } else if let initials, !initials.isEmpty {
                Text(initials)
                    .font(font.weight(.semibold))
                    .foregroundStyle(.tint)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(2)
            } else {
                Image(systemName: systemImage)
                    .font(font.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: diameter * typeScale, height: diameter * typeScale)
        .clipShape(Circle())
        .overlay {
            Circle().stroke(theme.border, lineWidth: theme.metrics.borderWidth)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isImage)
        .registryItem("avatar")
    }

    private var diameter: CGFloat {
        switch controlSize {
        case .mini: 24
        case .small: 32
        case .regular: 40
        case .large: 56
        case .extraLarge: 72
        @unknown default: 40
        }
    }

    private var font: Font {
        switch controlSize {
        case .mini: .caption2
        case .small: .caption
        case .regular: .subheadline
        case .large: .title3
        case .extraLarge: .title
        @unknown default: .subheadline
        }
    }
}

private struct AvatarPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Avatar(
                    Image(systemName: "person.crop.circle.fill"),
                    accessibilityLabel: Text(verbatim: "Mishmash Bakery")
                )
                Avatar(initials: "MK", accessibilityLabel: Text(verbatim: "Maya Khalid"))
                Avatar(accessibilityLabel: Text("Unknown sender"))
            }

            HStack(alignment: .bottom, spacing: 12) {
                Avatar(initials: "S", accessibilityLabel: Text("Salary"))
                    .controlSize(.mini)
                Avatar(initials: "S", accessibilityLabel: Text("Salary"))
                    .controlSize(.small)
                Avatar(initials: "S", accessibilityLabel: Text("Salary"))
                Avatar(initials: "S", accessibilityLabel: Text("Salary"))
                    .controlSize(.large)
                Avatar(initials: "S", accessibilityLabel: Text("Salary"))
                    .controlSize(.extraLarge)
            }
        }
        .padding()
    }
}

#Preview("Avatar") {
    AvatarPreview().tint(.indigo)
}

#Preview("Avatar Dark") {
    AvatarPreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Avatar Right to Left") {
    AvatarPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Avatar Accessibility Size") {
    AvatarPreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
