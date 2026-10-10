import Charts
import SwiftUI
import SweetUIFoundations

// Each demo renders the item's real `usage` snippet (plus its other variants)
// against the installed registry source, on the registry surface.

/// A row of controls that stacks when it cannot fit on one line, so button
/// and badge labels never get squeezed.
struct DemoRow<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { content }
            VStack(alignment: .leading, spacing: 12) { content }
        }
    }
}

/// Shared chrome for component demos: a surface with the variants inside.
struct DemoSurface<Content: View>: View {
    @Environment(\.registryTheme) private var theme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.metrics.standardSpacing)
        .registrySurface()
    }
}

struct BadgeDemo: View {
    var body: some View {
        DemoSurface {
            DemoRow {
                Text("New").registryBadge()
                Text("Secondary").registryBadge(.secondary)
                Text("Outline").registryBadge(.outline)
            }
            DemoRow {
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .registryBadge(.positive)
                Text("Needs attention").registryBadge(.destructive)
            }
        }
    }
}

struct ButtonDemo: View {
    var body: some View {
        DemoSurface {
            DemoRow {
                Button("Save changes") {}
                    .buttonStyle(.registry)
                Button("Cancel") {}
                    .buttonStyle(.registryOutline)
                Button("Delete", role: .destructive) {}
                    .buttonStyle(.registry)
            }
            DemoRow {
                Button("Secondary") {}
                    .buttonStyle(.registrySecondary)
                Button("Ghost") {}
                    .buttonStyle(.registryGhost)
                Button("Link") {}
                    .buttonStyle(.registryLink)
            }
            DemoRow {
                Button("Disabled") {}
                    .buttonStyle(.registry)
                    .disabled(true)
                Button("Small", systemImage: "plus") {}
                    .buttonStyle(.registryOutline)
                    .controlSize(.small)
                Button("Large") {}
                    .buttonStyle(.registrySecondary)
                    .controlSize(.large)
            }
        }
    }
}

struct ButtonGroupDemo: View {
    var body: some View {
        DemoSurface {
            ControlGroup {
                Button("Undo", systemImage: "arrow.uturn.backward") {}
                Button("Redo", systemImage: "arrow.uturn.forward") {}
            }
            .controlGroupStyle(.registryButtons)

            ControlGroup("Document actions") {
                Button("Save") {}
                Button("Duplicate") {}
                Button("Delete", role: .destructive) {}
            }
            .controlGroupStyle(RegistryButtonGroupStyle(.outline))
        }
    }
}

struct CardDemo: View {
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                LabeledContent("Plan", value: "Premium")
                LabeledContent("Renews", value: "12 September")
                Text("Manage billing and renewal details from your account settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("Subscription", systemImage: "creditcard.fill")
        }
        .groupBoxStyle(.registryCard)
    }
}

struct CheckboxDemo: View {
    @State private var accepted = true
    @State private var updates = false

    var body: some View {
        DemoSurface {
            Toggle("Accept terms", isOn: $accepted)
                .toggleStyle(.registryCheckbox)
            Toggle("Product updates", isOn: $updates)
                .toggleStyle(.registryCheckbox)
            Toggle("Unavailable option", isOn: .constant(false))
                .toggleStyle(.registryCheckbox)
                .disabled(true)
        }
    }
}

struct InputDemo: View {
    @Environment(\.registryTheme) private var theme
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        DemoSurface {
            TextField("Email", text: $email)
                .textFieldStyle(.registryInput)
                .accessibilityLabel("Email")
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
            SecureField("Password", text: $password)
                .textFieldStyle(.registryInput)
                .accessibilityLabel("Password")
            VStack(alignment: .leading, spacing: 4) {
                TextField("Work email", text: .constant("not-an-email"))
                    .textFieldStyle(RegistryInputStyle(isInvalid: true))
                    .accessibilityLabel("Work email")
                    .accessibilityHint("Enter a valid email address")
                Text("Enter a valid email address")
                    .font(.footnote)
                    .foregroundStyle(theme.negative)
            }
            TextField("Disabled", text: .constant("Unavailable"))
                .textFieldStyle(.registryInput)
                .accessibilityLabel("Disabled")
                .disabled(true)
        }
    }
}

struct LabelDemo: View {
    var body: some View {
        DemoSurface {
            Label("Account settings", systemImage: "person.crop.circle")
                .labelStyle(.registry)
            Label("Continue", systemImage: "chevron.forward")
                .labelStyle(.registryTrailingIcon)
        }
    }
}

struct MacroProgressDemo: View {
    var body: some View {
        DemoSurface {
            MacroProgress(
                "Protein",
                value: Text("96 g"),
                target: Text("130 g"),
                progress: 96.0 / 130.0,
                systemImage: "fish.fill"
            )
            .registryTint(.indigo)
            MacroProgress(
                "Carbohydrates",
                value: Text("182 g"),
                target: Text("240 g"),
                progress: 182.0 / 240.0,
                systemImage: "leaf.fill"
            )
            .registryTint(.green)
        }
    }
}

struct MetricCardDemo: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) { metrics }
            VStack(spacing: 16) { metrics }
        }
    }

    @ViewBuilder
    private var metrics: some View {
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
}

struct ProgressDemo: View {
    var body: some View {
        DemoSurface {
            ProgressView(value: 0.68) {
                Text("Uploading")
            } currentValueLabel: {
                Text("68 percent")
            }
            .progressViewStyle(.registryLinear)

            ProgressView("Preparing files")
                .progressViewStyle(.registryLinear)

            ProgressView(value: 1) {
                Text("Import complete")
            }
            .progressViewStyle(.registryLinearPositive)

            ProgressView(value: 0.32) {
                Text("Upload interrupted")
            }
            .progressViewStyle(.registryLinearNegative)
        }
    }
}

struct SelectDemo: View {
    @State private var currency = "KWD"

    var body: some View {
        DemoSurface {
            Picker("Currency", selection: $currency) {
                Text("Kuwaiti dinar").tag("KWD")
                Text("US dollar").tag("USD")
                Text("Euro").tag("EUR")
            }
            .registrySelect()

            Picker("Unavailable", selection: .constant("KWD")) {
                Text("Kuwaiti dinar").tag("KWD")
            }
            .registrySelect()
            .disabled(true)
        }
    }
}

struct SeparatorDemo: View {
    var body: some View {
        DemoSurface {
            Text("Account")
            Divider()
                .registrySeparator(insets: EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            HStack(spacing: 16) {
                Text("Profile")
                Divider().registrySeparator(.vertical)
                Text("Security")
            }
            .frame(height: 44)
        }
    }
}

struct SpinnerDemo: View {
    var body: some View {
        DemoSurface {
            ProgressView()
                .accessibilityLabel("Loading")
                .progressViewStyle(.registrySpinner)
            ProgressView("Loading results")
                .progressViewStyle(.registrySpinner)
        }
    }
}

struct TextareaDemo: View {
    @Environment(\.registryTheme) private var theme
    @State private var notes = "Leave the parcel with the concierge."

    var body: some View {
        DemoSurface {
            TextEditor(text: $notes)
                .registryTextArea(accessibilityLabel: Text("Delivery instructions"))
            VStack(alignment: .leading, spacing: 4) {
                TextEditor(text: .constant("Too short"))
                    .registryTextArea(
                        accessibilityLabel: Text("Request details"),
                        isInvalid: true,
                        minimumHeight: 80
                    )
                    .accessibilityHint("Enter at least 20 characters")
                Text("Enter at least 20 characters")
                    .font(.footnote)
                    .foregroundStyle(theme.negative)
            }
        }
    }
}

struct ToggleDemo: View {
    @State private var bold = true
    @State private var italic = false

    var body: some View {
        DemoSurface {
            HStack(spacing: 12) {
                Toggle("Bold", systemImage: "bold", isOn: $bold)
                Toggle("Italic", systemImage: "italic", isOn: $italic)
            }
            .labelStyle(.iconOnly)
            .toggleStyle(.registryToggle)
        }
    }
}

struct ToggleGroupDemo: View {
    @State private var bold = true
    @State private var italic = false
    @State private var underline = false

    var body: some View {
        DemoSurface {
            ControlGroup("Text formatting") {
                Toggle("Bold", systemImage: "bold", isOn: $bold)
                Toggle("Italic", systemImage: "italic", isOn: $italic)
                Toggle("Underline", systemImage: "underline", isOn: $underline)
            }
            .labelStyle(.iconOnly)
            .registryToggleGroup()
        }
    }
}

struct TransactionRowDemo: View {
    var body: some View {
        DemoSurface {
            TransactionRow(
                title: Text("Mishmash Bakery"),
                subtitle: Text("Today, 09:41"),
                amount: Text(-8.75, format: .currency(code: "KWD")),
                systemImage: "cup.and.saucer.fill"
            )
            .registryTone(.negative)
            Divider().registrySeparator()
            TransactionRow(
                title: Text("Salary"),
                subtitle: Text("Yesterday"),
                amount: Text(2_450, format: .currency(code: "KWD")),
                systemImage: "building.columns.fill"
            )
            .registryTone(.positive)
            Divider().registrySeparator()
            TransactionRow(
                title: Text("Pending transfer"),
                subtitle: Text("Yesterday"),
                amount: Text(120, format: .currency(code: "KWD")),
                systemImage: "arrow.left.arrow.right"
            )
        }
    }
}

struct AlertDemo: View {
    var body: some View {
        VStack(spacing: 16) {
            InlineAlert(
                "Card delivery delayed",
                message: Text("Your new card now arrives on Thursday.")
            )
            InlineAlert(
                "Import complete",
                message: Text("124 transactions were added.")
            )
            .registryVariant(.positive)
            InlineAlert(
                "Payment failed",
                message: Text("The card on file was declined.")
            ) {
                ViewThatFits(in: .horizontal) {
                    HStack {
                        Button("Retry") {}
                            .buttonStyle(.registry)
                        Button("Change card") {}
                            .buttonStyle(.registryOutline)
                    }
                    VStack(alignment: .leading) {
                        Button("Retry") {}
                            .buttonStyle(.registry)
                        Button("Change card") {}
                            .buttonStyle(.registryOutline)
                    }
                }
            }
            .registryVariant(.destructive)
        }
    }
}

struct AvatarDemo: View {
    var body: some View {
        DemoSurface {
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
    }
}

struct SkeletonDemo: View {
    @Environment(\.registryTheme) private var theme
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            Toggle("Loading", isOn: $isLoading)
                .toggleStyle(.switch)

            DemoSurface {
                ForEach(0..<3, id: \.self) { index in
                    ItemRow(
                        title: Text("Mishmash Bakery order \(index + 1)"),
                        description: Text("Card payment of KWD 8.750")
                    ) {
                        Avatar(initials: "MB", accessibilityLabel: Text("Mishmash Bakery"))
                    } accessory: {
                        Text("09:4\(index)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .registrySkeleton(isLoading)
        }
    }
}

struct EmptyDemo: View {
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
                    .buttonStyle(.registryOutline)
            }
            .registryEmptyState()
        }
    }
}

struct AccordionDemo: View {
    @Environment(\.registryTheme) private var theme
    @State private var isFirstExpanded = true
    @State private var isSecondExpanded = false
    @State private var isThirdExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            DisclosureGroup("Is my card contactless?", isExpanded: $isFirstExpanded) {
                Text("Yes. Hold it near the terminal until it confirms the payment.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Divider().registrySeparator()
            DisclosureGroup("How do I freeze my card?", isExpanded: $isSecondExpanded) {
                Text("Open the card, then choose Freeze. Unfreeze the same way.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Divider().registrySeparator()
            DisclosureGroup("Can I change my PIN?", isExpanded: $isThirdExpanded) {
                Text("Yes, from the card's settings or at any of our ATMs.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .disclosureGroupStyle(.registryAccordion)
        .padding(.horizontal, theme.metrics.standardSpacing)
        .registrySurface()
    }
}

struct ItemDemo: View {
    @Environment(\.registryTheme) private var theme
    @State private var limitEnabled = true

    var body: some View {
        VStack(spacing: 0) {
            Button {} label: {
                ItemRow(
                    title: Text("Mishmash Bakery"),
                    description: Text("Card ending 4021 · Today, 09:41")
                ) {
                    Avatar(initials: "MB", accessibilityLabel: Text("Mishmash Bakery"))
                } accessory: {
                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, theme.metrics.standardSpacing)
            }
            .buttonStyle(.plain)

            Divider().registrySeparator()

            ItemRow(
                title: Text("Statement ready"),
                description: Text("August 2026"),
                accessory: {
                    Text("New").registryBadge()
                }
            )
            .padding(.vertical, theme.metrics.standardSpacing)

            Divider().registrySeparator()

            // A switch row: the row is the toggle's label, so its words are
            // part of the control and are spoken once.
            Toggle(isOn: $limitEnabled) {
                ItemRow(
                    title: Text("Spending limit"),
                    description: Text("Applies to online purchases.")
                )
            }
            .toggleStyle(.switch)
            .padding(.vertical, theme.metrics.standardSpacing)
        }
        .padding(.horizontal, theme.metrics.standardSpacing)
        .registrySurface()
    }
}

struct InputGroupDemo: View {
    @State private var query = ""
    @State private var amount = 120.0

    var body: some View {
        DemoSurface {
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
            Text("Enter an amount below your daily limit")
                .font(.footnote)
                .foregroundStyle(.red)
        }
    }
}

struct KeycapDemo: View {
    var body: some View {
        DemoSurface {
            HStack {
                Text("Open search")
                Spacer()
                Text("⌘K").registryKeycap(accessibilityLabel: Text("Command K"))
            }
            HStack {
                Text("Run the highlighted command")
                Spacer()
                Text("↩").registryKeycap(accessibilityLabel: Text("Return"))
            }
            HStack {
                Text("Dismiss")
                Spacer()
                Text("esc").registryKeycap(accessibilityLabel: Text("Escape"))
            }
        }
    }
}

struct CommandPaletteDemo: View {
    @State private var query = ""

    var body: some View {
        CommandPalette(
            query: $query,
            prompt: "Search actions and activity",
            sections: DemoCommands.sections(matching: query),
            emptyDescription: Text("Try a payee, a card, or an action."),
            onSelect: { _ in }
        )
    }
}

/// Caller-owned command data and filtering shared by the palette and block demos.
enum DemoCommands {
    struct Command {
        let id: String
        let name: String
        let detail: String?
        let symbol: String
        let shortcut: String?
        let shortcutLabel: String?
        let section: String
    }

    static let all: [Command] = [
        Command(id: "transfer", name: "New transfer", detail: "Send money to a saved payee", symbol: "arrow.up.right", shortcut: "⌘T", shortcutLabel: "Command T", section: "Actions"),
        Command(id: "freeze", name: "Freeze card", detail: nil, symbol: "snowflake", shortcut: nil, shortcutLabel: nil, section: "Actions"),
        Command(id: "statement", name: "Download statement", detail: "August 2026", symbol: "doc.text", shortcut: nil, shortcutLabel: nil, section: "Actions"),
        Command(id: "bakery", name: "Mishmash Bakery", detail: "KWD 8.750, today", symbol: "cup.and.saucer.fill", shortcut: nil, shortcutLabel: nil, section: "Recent"),
        Command(id: "salary", name: "Salary", detail: "KWD 2,450.000, yesterday", symbol: "building.columns.fill", shortcut: nil, shortcutLabel: nil, section: "Recent"),
    ]

    static func sections(matching query: String) -> [CommandSection<String>] {
        // Section titles stay literals so a string catalog can extract them.
        let groups: [(id: String, title: LocalizedStringResource)] = [
            ("Actions", "Actions"),
            ("Recent", "Recent")
        ]
        return groups.map { group in
            CommandSection(
                id: group.id,
                title: group.title,
                entries: all
                    .filter { $0.section == group.id }
                    .filter { query.isEmpty || $0.name.localizedStandardContains(query) }
                    .map {
                        CommandEntry(
                            id: $0.id,
                            title: Text($0.name),
                            detail: $0.detail.map { Text($0) },
                            systemImage: $0.symbol,
                            shortcut: $0.shortcut,
                            shortcutLabel: $0.shortcutLabel.map { Text($0) }
                        )
                    }
            )
        }
    }
}

struct ValidatedInputDemo: View {
    @State private var email = "maya@example"
    @State private var password = ""
    @State private var confirmation = ""
    @State private var phone = "+96599123456"

    var body: some View {
        DemoSurface {
            VStack(spacing: 24) {
                ValidatedInput("Email", text: $email, validations: [.required, .email])
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                ValidatedInput(
                    "Password", text: $password, validations: [.required, .password()], isSecure: true)
                ValidatedInput(
                    "Confirm password", text: $confirmation,
                    validations: [.required, .matching(password)], isSecure: true)
                ValidatedInput("Phone", text: $phone, validations: [.required, .internationalPhone])
                    .keyboardType(.phonePad)
            }
        }
    }
}

struct FieldDemo: View {
    @State private var name = "Maya Khalid"
    @State private var email = "not-an-email"
    @State private var role = "member"

    var body: some View {
        DemoSurface {
            FieldGroup {
                Field("Full name", description: "As it appears on your card.") { _ in
                    TextField("Full name", text: $name)
                        .textFieldStyle(.registryInput)
                        .accessibilityLabel("Full name")
                }
                Field("Email", error: "Enter a valid email address.") { isInvalid in
                    TextField("you@example.com", text: $email)
                        .textFieldStyle(RegistryInputStyle(isInvalid: isInvalid))
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .accessibilityLabel("Email")
                }
                Field("Role") { _ in
                    Picker("Role", selection: $role) {
                        Text("Member").tag("member")
                        Text("Admin").tag("admin")
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Role")
                }
            }
        }
    }
}

private struct DemoInvoiceLine: Identifiable {
    let id = UUID()
    let item: String
    let quantity: Int
    let unitPrice: Decimal
}

struct TableDemo: View {
    private let lines = [
        DemoInvoiceLine(item: "Design system license", quantity: 1, unitPrice: 499),
        DemoInvoiceLine(item: "Priority support", quantity: 12, unitPrice: 99),
        DemoInvoiceLine(item: "Custom components", quantity: 3, unitPrice: 250),
    ]

    private var subtotal: Decimal {
        lines.reduce(0) { $0 + Decimal($1.quantity) * $1.unitPrice }
    }

    var body: some View {
        DemoSurface {
            DataTable(
                lines,
                columns: [
                    DataTableColumn(Text("Item")) { line in
                        Text(line.item)
                    },
                    DataTableColumn(Text("Qty"), alignment: .trailing) { line in
                        Text(line.quantity, format: .number)
                    },
                    DataTableColumn(Text("Rate"), alignment: .trailing) { line in
                        Text(line.unitPrice, format: .currency(code: "USD"))
                    },
                    DataTableColumn(Text("Amount"), alignment: .trailing) { line in
                        Text(Decimal(line.quantity) * line.unitPrice, format: .currency(code: "USD"))
                    },
                ],
                footer: [
                    DataTableFooterRow(label: Text("Subtotal"), value: Text(subtotal, format: .currency(code: "USD"))),
                    DataTableFooterRow(label: Text("Tax"), value: Text(0, format: .currency(code: "USD"))),
                    DataTableFooterRow(
                        label: Text("Total due"),
                        value: Text(subtotal, format: .currency(code: "USD")),
                        isEmphasized: true
                    ),
                ]
            )
        }
    }
}

struct BreadcrumbDemo: View {
    var body: some View {
        DemoSurface {
            Breadcrumb([
                BreadcrumbItem(Text("Home"), action: {}),
                BreadcrumbItem(Text("Library"), action: {}),
                BreadcrumbItem(Text("Payments")),
            ])

            Breadcrumb([
                BreadcrumbItem(Text("Home"), action: {}),
                BreadcrumbItem(Text("Accounts"), action: {}),
                BreadcrumbItem(Text("Cards"), action: {}),
                BreadcrumbItem(Text("Statements"), action: {}),
                BreadcrumbItem(Text("August 2026")),
            ])
            .frame(width: 240, alignment: .leading)
        }
    }
}

struct ComboboxDemo: View {
    @State private var timezone: String? = "riyadh"

    private let zones = [
        ComboboxOption(id: "kuwait", title: "Kuwait City", systemImage: "clock"),
        ComboboxOption(id: "riyadh", title: "Riyadh", systemImage: "clock"),
        ComboboxOption(id: "dubai", title: "Dubai", systemImage: "clock"),
        ComboboxOption(id: "doha", title: "Doha", systemImage: "clock"),
    ]

    var body: some View {
        DemoSurface {
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
    }
}

private struct DemoChannelVisits: Identifiable {
    let id = UUID()
    let month: String
    let channel: String
    let visits: Int
}

private struct DemoMonthlyBalance: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
}

private struct DemoBrowserShare: Identifiable {
    let id = UUID()
    let browser: String
    let share: Double
}

struct ChartDemo: View {
    private let visits = [
        DemoChannelVisits(month: "Jan", channel: "Desktop", visits: 186),
        DemoChannelVisits(month: "Jan", channel: "Mobile", visits: 80),
        DemoChannelVisits(month: "Feb", channel: "Desktop", visits: 205),
        DemoChannelVisits(month: "Feb", channel: "Mobile", visits: 130),
        DemoChannelVisits(month: "Mar", channel: "Desktop", visits: 237),
        DemoChannelVisits(month: "Mar", channel: "Mobile", visits: 120),
        DemoChannelVisits(month: "Apr", channel: "Desktop", visits: 173),
        DemoChannelVisits(month: "Apr", channel: "Mobile", visits: 190),
    ]

    private let balances = [
        DemoMonthlyBalance(month: "Jan", amount: 2.1),
        DemoMonthlyBalance(month: "Feb", amount: 2.6),
        DemoMonthlyBalance(month: "Mar", amount: 2.4),
        DemoMonthlyBalance(month: "Apr", amount: 3.1),
        DemoMonthlyBalance(month: "May", amount: 3.5),
    ]

    private let shares = [
        DemoBrowserShare(browser: "Safari", share: 38),
        DemoBrowserShare(browser: "Chrome", share: 34),
        DemoBrowserShare(browser: "Firefox", share: 16),
        DemoBrowserShare(browser: "Edge", share: 12),
    ]

    var body: some View {
        DemoSurface {
            chart("Traffic by channel") {
                Chart(visits) { row in
                    BarMark(
                        x: .value("Month", row.month),
                        y: .value("Visits", row.visits)
                    )
                    .foregroundStyle(by: .value("Channel", row.channel))
                    .position(by: .value("Channel", row.channel))
                }
                .registryChart()
                .frame(height: 160)
            }

            chart("Balance trend") {
                Chart(balances) { row in
                    LineMark(
                        x: .value("Month", row.month),
                        y: .value("Balance", row.amount)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(TintShapeStyle())
                }
                .registryChart()
                .frame(height: 105)
            }

            chart("Cumulative inflow") {
                Chart(balances) { row in
                    AreaMark(
                        x: .value("Month", row.month),
                        y: .value("Balance", row.amount)
                    )
                    .foregroundStyle(TintShapeStyle().opacity(0.2))
                    LineMark(
                        x: .value("Month", row.month),
                        y: .value("Balance", row.amount)
                    )
                    .foregroundStyle(TintShapeStyle())
                }
                .registryChart()
                .frame(height: 105)
            }

            chart("Browser share") {
                Chart(shares) { row in
                    SectorMark(
                        angle: .value("Share", row.share),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Browser", row.browser))
                }
                .registryChart()
                .frame(height: 170)
            }
        }
    }

    @ViewBuilder
    private func chart(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
            content()
        }
    }
}

struct FoldCompanionDemo: View {
    @State private var isShowingDetails = false

    var body: some View {
        NavigationStack {
            List {
                LabeledContent("Merchant", value: "Mishmash Bakery")
                LabeledContent("Amount", value: "KWD 8.750")
            }
            .navigationTitle("Transaction")
            .toolbar {
                Button("Details", systemImage: "sidebar.trailing") {
                    isShowingDetails.toggle()
                }
            }
            .foldCompanion(isPresented: $isShowingDetails) {
                List {
                    LabeledContent("Category", value: "Dining")
                    LabeledContent("Status", value: "Cleared")
                }
            }
        }
        .frame(height: 360)
        .registrySurface()
    }
}
