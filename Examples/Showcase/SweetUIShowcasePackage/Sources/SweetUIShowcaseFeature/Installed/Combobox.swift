import SwiftUI
import SweetUIFoundations

/// One selectable option in a ``Combobox``. The title is the plain, editable
/// text shown in the field and matched against the query; an optional symbol
/// is decorative media on the option row.
public struct ComboboxOption<ID: Hashable>: Identifiable {
    public let id: ID
    public let title: String
    public let systemImage: String?

    public init(id: ID, title: String, systemImage: String? = nil) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
    }
}

/// A searchable single-selection control: a registry-styled search field over
/// caller-provided options, with a filtered list that opens below the field on
/// focus and a native empty state when nothing matches. Selection is controlled
/// through the binding; filtering and the option data stay with the caller.
///
/// The list opens inline below the field rather than in a popover: on a compact
/// iPhone width a popover presents as a full sheet, which is heavier than a
/// single-select filter warrants, so the lightest presentation (an inline
/// dropdown that pushes content, never overlays it) is used instead.
public struct Combobox<ID: Hashable>: View {
    @Environment(\.registryTheme) private var theme
    // The symbol column scales with the body text the symbols are drawn in.
    @ScaledMetric(relativeTo: .body) private var symbolWidth: CGFloat = 28

    @Binding private var selection: ID?
    private let options: [ComboboxOption<ID>]
    private let prompt: LocalizedStringResource
    private let emptyTitle: LocalizedStringResource
    private let emptyDescription: Text?

    @State private var query: String = ""
    @FocusState private var isFocused: Bool

    public init(
        selection: Binding<ID?>,
        options: [ComboboxOption<ID>],
        prompt: LocalizedStringResource = LocalizedStringResource("Search", comment: "Placeholder inside the combobox search field"),
        emptyTitle: LocalizedStringResource = "No results",
        emptyDescription: Text? = nil
    ) {
        self._selection = selection
        self.options = options
        self.prompt = prompt
        self.emptyTitle = emptyTitle
        self.emptyDescription = emptyDescription
    }

    private var selectedOption: ComboboxOption<ID>? {
        options.first { $0.id == selection }
    }

    private var filtered: [ComboboxOption<ID>] {
        // An empty query, or a query still equal to the selected title, browses
        // every option; anything else filters case- and diacritic-insensitively.
        guard !query.isEmpty, query != selectedOption?.title else { return options }
        return options.filter { $0.title.localizedStandardContains(query) }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            InputGroup {
                Image(systemName: "magnifyingglass")
                    .accessibilityHidden(true)
            } content: {
                TextField(text: $query, prompt: Text(prompt)) {
                    Text(prompt)
                }
                .accessibilityLabel(Text(prompt))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
                .focused($isFocused)
            } trailing: {
                if isFocused {
                    if !query.isEmpty {
                        Button("Clear", systemImage: "xmark.circle.fill") {
                            query = ""
                            selection = nil
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.registryGhost)
                        .controlSize(.small)
                    }
                } else {
                    Button("Show options", systemImage: "chevron.up.chevron.down") {
                        isFocused = true
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.registryGhost)
                    .controlSize(.small)
                }
            }

            if isFocused {
                list
            }
        }
        .onAppear { syncQueryToSelection() }
        .onChange(of: selection) { _, _ in
            if !isFocused { syncQueryToSelection() }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused { syncQueryToSelection() }
        }
        .registryItem("combobox")
    }

    @ViewBuilder
    private var list: some View {
        if filtered.isEmpty {
            ContentUnavailableView(
                emptyTitle,
                systemImage: "magnifyingglass",
                description: emptyDescription
            )
            .registryEmptyState()
        } else {
            VStack(spacing: 0) {
                ForEach(filtered) { option in
                    optionRow(option)
                    if option.id != filtered.last?.id {
                        Divider().registrySeparator()
                    }
                }
            }
            .padding(.horizontal, theme.metrics.standardSpacing)
            .registrySurface()
        }
    }

    private func optionRow(_ option: ComboboxOption<ID>) -> some View {
        Button {
            selection = option.id
            query = option.title
            isFocused = false
        } label: {
            ItemRow(title: Text(option.title)) {
                if let symbol = option.systemImage {
                    Image(systemName: symbol)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.tint)
                        .frame(width: symbolWidth)
                        .accessibilityHidden(true)
                }
            } accessory: {
                if option.id == selection {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, theme.metrics.compactSpacing)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(option.id == selection ? .isSelected : [])
        .accessibilityInputLabels([option.title])
    }

    private func syncQueryToSelection() {
        query = selectedOption?.title ?? ""
    }
}

private struct ComboboxPreview: View {
    @State private var timezone: String? = "riyadh"

    private let zones = [
        ComboboxOption(id: "kuwait", title: "Kuwait City", systemImage: "clock"),
        ComboboxOption(id: "riyadh", title: "Riyadh", systemImage: "clock"),
        ComboboxOption(id: "dubai", title: "Dubai", systemImage: "clock"),
        ComboboxOption(id: "doha", title: "Doha", systemImage: "clock"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Combobox(
                selection: $timezone,
                options: zones,
                prompt: "Search time zones",
                emptyDescription: Text("Try a city name.")
            )
            Text("Selected: \(timezone ?? "none")")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview("Combobox") {
    ComboboxPreview().tint(.indigo)
}

#Preview("Combobox Dark") {
    ComboboxPreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Combobox Right to Left") {
    ComboboxPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Combobox Accessibility Size") {
    ComboboxPreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
