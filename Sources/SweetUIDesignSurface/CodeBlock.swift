#if canImport(UIKit)
import SwiftUI
import SweetUIFoundations

/// Monospaced code on the registry surface with a copy action.
public struct CodeBlock: View {
    @Environment(\.registryTheme) private var theme
    let code: String

    public init(_ code: String) {
        self.code = code
    }

    public var body: some View {
        // Wrapping text, not a horizontal scroll view: long lines wrap at
        // large text sizes, and a hosted scroll view inside a pushed screen
        // crashed with NaN bounds under right-to-left plus accessibility size.
        Text(code)
            .font(.footnote.monospaced())
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(theme.metrics.standardSpacing)
            .padding(.trailing, 40)
            .registrySurface()
        .overlay(alignment: .topTrailing) {
            CopyButton("Copy code", text: code)
                .labelStyle(.iconOnly)
                // A native style, not the registry button item: this is a
                // package product and items are copied source.
                .buttonStyle(.borderless)
                .controlSize(.small)
                .background(.regularMaterial, in: Circle())
                .padding(theme.metrics.compactSpacing / 2)
        }
    }
}
#endif
