import SwiftUI
import SweetUIFoundations

public extension View {
    /// Places a native `ContentUnavailableView` on the registry content surface
    /// so an empty section sits where its content would, full width and framed
    /// like the rows it replaces. Nothing about the native view changes: title,
    /// symbol, description, and actions remain the caller's.
    func registryEmptyState() -> some View {
        modifier(RegistryEmptyStateModifier())
    }
}

private struct RegistryEmptyStateModifier: ViewModifier {
    @Environment(\.registryTheme) private var theme

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(theme.metrics.standardSpacing)
            .registrySurface()
            .registryItem("empty")
    }
}

private struct RegistryEmptyStateModifierPreview: View {
    var body: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "No recent activity",
                systemImage: "clock.arrow.circlepath",
                description: Text("New transactions will appear here.")
            )
            .registryEmptyState()

            ContentUnavailableView {
                Label("No results for “bakery”", systemImage: "magnifyingglass")
            } description: {
                Text("Check the spelling or try a broader search.")
            } actions: {
                Button("Clear search") {}
                    .buttonStyle(.bordered)
            }
            .registryEmptyState()
        }
        .padding()
    }
}

#Preview("Empty State") {
    RegistryEmptyStateModifierPreview().tint(.indigo)
}

#Preview("Empty State Dark") {
    RegistryEmptyStateModifierPreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Empty State Right to Left") {
    RegistryEmptyStateModifierPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Empty State Accessibility Size") {
    RegistryEmptyStateModifierPreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
