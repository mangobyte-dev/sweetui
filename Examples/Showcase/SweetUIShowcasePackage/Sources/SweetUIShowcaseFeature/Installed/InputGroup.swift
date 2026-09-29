import SwiftUI
import SweetUIFoundations

/// Registry input chrome around a native text field plus caller-provided
/// leading and trailing accessories, such as a search symbol and a clear
/// button. The field stays a plain `TextField` or `SecureField` at the call
/// site; the group owns the surface, border, focus ring, and spacing.
public struct InputGroup<Leading: View, Content: View, Trailing: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.registryTheme) private var theme
    @FocusState private var isFocused: Bool

    private let isInvalid: Bool
    private let leading: Leading
    private let content: Content
    private let trailing: Trailing

    /// - Parameters:
    ///   - isInvalid: Draws the negative border and the emphasized width.
    ///   - leading: Decorative or interactive content before the field.
    ///   - content: The native field; the group applies `.plain` style and focus.
    ///   - trailing: Content after the field, typically a button.
    public init(
        isInvalid: Bool = false,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.isInvalid = isInvalid
        self.leading = leading()
        self.content = content()
        self.trailing = trailing()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)

        HStack(spacing: theme.metrics.compactSpacing) {
            leading
                .foregroundStyle(.secondary)
            content
                .textFieldStyle(.plain)
                .focused($isFocused)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            trailing
        }
        .padding(.horizontal, theme.metrics.controlHorizontalPadding)
        .frame(minHeight: RegistryMetrics.minimumHitSize)
        .background(theme.surface, in: shape)
        .overlay {
            shape.stroke(
                borderStyle,
                lineWidth: isFocused || isInvalid
                    ? theme.metrics.emphasizedBorderWidth
                    : theme.metrics.borderWidth
            )
        }
        .opacity(isEnabled ? 1 : theme.disabledOpacity)
        .registryItem("input-group")
    }

    private var borderStyle: AnyShapeStyle {
        if isInvalid {
            AnyShapeStyle(theme.negative)
        } else if isFocused {
            AnyShapeStyle(TintShapeStyle())
        } else {
            AnyShapeStyle(theme.border)
        }
    }
}

public extension InputGroup where Leading == EmptyView {
    init(
        isInvalid: Bool = false,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(isInvalid: isInvalid, leading: { EmptyView() }, content: content, trailing: trailing)
    }
}

public extension InputGroup where Trailing == EmptyView {
    init(
        isInvalid: Bool = false,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder content: () -> Content
    ) {
        self.init(isInvalid: isInvalid, leading: leading, content: content, trailing: { EmptyView() })
    }
}

private struct InputGroupPreview: View {
    @State private var query = ""
    @State private var amount = 120.0

    var body: some View {
        VStack(spacing: 16) {
            InputGroup {
                Image(systemName: "magnifyingglass")
                    .accessibilityHidden(true)
            } content: {
                TextField("Search transactions", text: $query)
                    .accessibilityLabel("Search transactions")
            } trailing: {
                if !query.isEmpty {
                    Button("Clear search", systemImage: "xmark.circle.fill") { query = "" }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.registryGhost)
                        .controlSize(.small)
                }
            }

            InputGroup(isInvalid: true) {
                Text("KWD")
                    .font(.subheadline.weight(.medium))
            } content: {
                TextField("Amount", value: $amount, format: .number)
                    .keyboardType(.decimalPad)
                    .accessibilityLabel("Amount in KWD")
                    .accessibilityHint("Enter an amount below your daily limit")
            }
        }
        .padding()
    }
}

#Preview("Input Group") {
    InputGroupPreview().tint(.indigo)
}

#Preview("Input Group Dark") {
    InputGroupPreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Input Group Right to Left") {
    InputGroupPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Input Group Accessibility Size") {
    InputGroupPreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
