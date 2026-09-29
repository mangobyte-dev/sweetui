<!-- Reference for the sweetui skills. Generated from Website/content/registry.json (a build product of `sweetui generate site-data`) by a throwaway script. Every snippet is the item's own `usage` field, quoted from its canonical source. Do not hand-edit; regenerate when the catalog changes. -->

# Usage snippets

One minimal call-site snippet per item, quoted verbatim from each item's `usage` field. Compose through this public API rather than writing the item from memory.


## Components


### accordion (component 0.2.2)


```swift
@State private var isExpanded = false

DisclosureGroup("How do I freeze my card?", isExpanded: $isExpanded) {
    Text("Open the card, then choose Freeze.")
}
.disclosureGroupStyle(.registryAccordion)
```


### alert (component 0.2.1)


```swift
InlineAlert(
    "Card delivery delayed",
    message: Text("Your new card now arrives on Thursday.")
)

InlineAlert(
    "Payment failed",
    message: Text("The card on file was declined.")
) {
    Button("Retry") {}
        .buttonStyle(.registry)
}
.registryVariant(.destructive)
```


### attachment (component 0.1.1)


```swift
AttachmentRow(
    name: Text("Statement-Aug-2026.pdf"),
    detail: Text("PDF document, 1.2 MB"),
    state: .uploading(progress: 0.68)
) {
    Image(systemName: "doc.fill")
} actions: {
    Button("Cancel", systemImage: "xmark") {}
        .labelStyle(.iconOnly)
        .buttonStyle(.registryGhost)
        .accessibilityLabel("Cancel upload")
}
```


### avatar (component 0.2.1)


```swift
Avatar(Image("maya"), accessibilityLabel: Text("Maya Khalid"))

Avatar(initials: "MK", accessibilityLabel: Text("Maya Khalid"))
    .controlSize(.large)

Avatar(accessibilityLabel: Text("Unknown sender"))
```


### badge (component 0.3.2)


```swift
Text("New")
    .registryBadge()

Label("Completed", systemImage: "checkmark.circle.fill")
    .registryBadge(.positive)
```


### breadcrumb (component 0.1.2)


```swift
Breadcrumb([
    BreadcrumbItem(Text("Home"), action: { path = NavigationPath() }),
    BreadcrumbItem(Text("Library"), action: { path.removeLast() }),
    BreadcrumbItem(Text("Payments"))
])
```


### bubble (component 0.1.1)


```swift
Text("Are we still on for Thursday?")
    .registryBubble(.incoming)

Text("Yes, 6pm works.")
    .registryBubble(.outgoing)
```


### button (component 0.5.2)


```swift
// Content layer only. In toolbars, tab bars, or floating chrome the system supplies Liquid Glass; use .buttonStyle(.glass) or .buttonStyle(.glassProminent) there instead of .registry styles.

Button("Save changes") {}
    .buttonStyle(.registry)

Button("Cancel") {}
    .buttonStyle(.registryOutline)

Button("Delete", role: .destructive) {}
    .buttonStyle(.registry)
```


### button-group (component 0.3.2)


```swift
// Content layer only. In toolbars, tab bars, or floating chrome the system supplies Liquid Glass; use .buttonStyle(.glass) or .buttonStyle(.glassProminent) there instead of .registry styles.

ControlGroup {
    Button("Undo", systemImage: "arrow.uturn.backward") {}
    Button("Redo", systemImage: "arrow.uturn.forward") {}
}
.controlGroupStyle(.registryButtons)
```


### card (component 0.2.1)


```swift
GroupBox {
    Text("Manage billing and renewal details from your account settings.")
} label: {
    Label("Subscription", systemImage: "creditcard.fill")
}
.groupBoxStyle(.registryCard)
```


### chart (component 0.1.3)


```swift
Chart(data) { row in
    BarMark(
        x: .value("Month", row.month),
        y: .value("Visits", row.visits)
    )
    .foregroundStyle(by: .value("Channel", row.channel))
    .position(by: .value("Channel", row.channel))
}
.registryChart()
.frame(height: 180)
```


### checkbox (component 0.3.2)


```swift
@State private var accepted = false

Toggle("Accept terms", isOn: $accepted)
    .toggleStyle(.registryCheckbox)
```


### combobox (component 0.1.1)


```swift
@State private var timezone: String? = "riyadh"

Combobox(
    selection: $timezone,
    options: [
        ComboboxOption(id: "kuwait", title: "Kuwait City", systemImage: "clock"),
        ComboboxOption(id: "riyadh", title: "Riyadh", systemImage: "clock")
    ],
    prompt: "Search time zones",
    emptyDescription: Text("Try a city name.")
)
```


### command (component 0.2.1)


```swift
@State private var query = ""

CommandPalette(
    query: $query,
    prompt: "Search actions",
    sections: [
        CommandSection(id: "actions", title: "Actions", entries: [
            CommandEntry(id: "transfer", title: Text("New transfer"), systemImage: "arrow.up.right", shortcut: "⌘T", shortcutLabel: Text("Command T"))
        ])
    ],
    onSelect: { id in }
)
```


### empty (component 0.1.1)


```swift
ContentUnavailableView(
    "No recent activity",
    systemImage: "clock.arrow.circlepath",
    description: Text("New transactions will appear here.")
)
.registryEmptyState()
```


### field (component 0.1.1)


```swift
@State private var email = ""

FieldGroup {
    Field("Full name", description: "As it appears on your card.") { _ in
        TextField("Full name", text: $name)
            .textFieldStyle(.registryInput)
            .accessibilityLabel("Full name")
    }
    Field("Email", error: emailError) { isInvalid in
        TextField("you@example.com", text: $email)
            .textFieldStyle(RegistryInputStyle(isInvalid: isInvalid))
            .accessibilityLabel("Email")
    }
}
```


### input (component 0.5.1)


```swift
@State private var email = ""
@State private var password = ""

// The title is placeholder text to VoiceOver; the explicit label names
// the field once it holds text.
TextField("Email", text: $email)
    .textFieldStyle(.registryInput)
    .accessibilityLabel("Email")

SecureField("Password", text: $password)
    .textFieldStyle(.registryInput)
    .accessibilityLabel("Password")

TextField("Email", text: $email)
    .textFieldStyle(RegistryInputStyle(isInvalid: true))
    .accessibilityLabel("Email")
    .accessibilityHint("Enter a valid email address")
```


### input-group (component 0.2.1)


```swift
@State private var query = ""

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
```


### item (component 0.2.1)


```swift
ItemRow(
    title: Text("Statement ready"),
    description: Text("August 2026")
) {
    Avatar(initials: "ST", accessibilityLabel: Text("Statements"))
} accessory: {
    Text("New").registryBadge()
}
```


### kbd (component 0.1.2)


```swift
Text(verbatim: "⌘K")
    .registryKeycap(accessibilityLabel: Text("Command K"))

Text(verbatim: "esc")
    .registryKeycap()
```


### label (component 0.2.1)


```swift
Label("Account settings", systemImage: "person.crop.circle")
    .labelStyle(.registry)

Label("Continue", systemImage: "chevron.forward")
    .labelStyle(.registryTrailingIcon)
```


### macro-progress (component 0.4.1)


```swift
MacroProgress(
    "Protein",
    value: Text("96 g"),
    target: Text("130 g"),
    progress: 96.0 / 130.0,
    systemImage: "fish.fill"
)
.registryTint(.indigo)
```


### marker (component 0.1.1)


```swift
Text("Today")
    .registryMarker(.separator)

Text("Maya joined the conversation")
    .registryMarker()

Text("Delivered 09:41")
    .registryMarker(.status)
```


### message (component 0.1.1)


```swift
MessageRow(
    author: Text("Maya"),
    timestamp: Text("09:41"),
    status: Text("Delivered")
) {
    Avatar(initials: "MK", accessibilityLabel: Text("Maya Khalid"))
} content: {
    Text("Are we still on for Thursday?")
}

MessageRow {
    Text("Yes, 6pm works.")
}
.registryVariant(.outgoing)
```


### message-scroller (component 0.1.1)


```swift
MessageScroller(position: $position, isFollowing: $isFollowing) {
    ForEach(messages) { message in
        MessageRow {
            Text(message.text)
        }
        .registryVariant(message.isMine ? .outgoing : .incoming)
        .id(message.id)
    }
}
```


### metric-card (component 0.2.2)


```swift
MetricCard(
    "Available balance",
    value: Text(12_480.32, format: .currency(code: "USD")),
    detail: Text("Up 8.2% this month"),
    systemImage: "creditcard.fill"
)
```


### progress (component 0.2.1)


```swift
ProgressView(value: 0.68) {
    Text("Uploading")
} currentValueLabel: {
    Text("68 percent")
}
.progressViewStyle(.registryLinear)

ProgressView(value: 1) {
    Text("Import complete")
}
.progressViewStyle(.registryLinearPositive)
```


### select (component 0.2.1)


```swift
@State private var currency = "KWD"

Picker("Currency", selection: $currency) {
    Text("Kuwaiti dinar").tag("KWD")
    Text("US dollar").tag("USD")
}
.registrySelect()
```


### separator (component 0.2.1)


```swift
Divider()
    .registrySeparator(insets: EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

Divider()
    .registrySeparator(.vertical)
```


### skeleton (component 0.2.1)


```swift
@State private var isLoading = true

ActivityRows()
    .registrySkeleton(isLoading)

// Pass false to render the real content unchanged.
```


### spinner (component 0.2.1)


```swift
ProgressView("Loading results")
    .progressViewStyle(.registrySpinner)
```


### table (component 0.1.1)


```swift
DataTable(
    lines,
    columns: [
        DataTableColumn(Text("Item")) { Text($0.item) },
        DataTableColumn(Text("Qty"), alignment: .trailing) { Text($0.quantity, format: .number) },
        DataTableColumn(Text("Amount"), alignment: .trailing) { Text($0.amount, format: .currency(code: "USD")) }
    ],
    footer: [
        DataTableFooterRow(label: Text("Total due"), value: Text(total, format: .currency(code: "USD")), isEmphasized: true)
    ]
)
```


### textarea (component 0.4.1)


```swift
@State private var notes = ""

TextEditor(text: $notes)
    .registryTextArea(accessibilityLabel: Text("Delivery instructions"))
```


### toast (component 0.1.1)


```swift
@State private var toast: RegistryToast?

CardDetail()
    .registryToast($toast)

// Present a destructive toast with an undo action:
toast = RegistryToast(
    title: "Message deleted",
    variant: .destructive,
    action: RegistryToast.Action(label: "Undo") { restoreMessage() }
)
```


### toggle (component 0.2.1)


```swift
// Content layer only. In toolbars, tab bars, or floating chrome the system supplies Liquid Glass; use .buttonStyle(.glass) or .buttonStyle(.glassProminent) there instead of .registry styles.

@State private var bold = false

Toggle("Bold", systemImage: "bold", isOn: $bold)
    .toggleStyle(.registryToggle)
```


### toggle-group (component 0.2.1)


```swift
// Content layer only. In toolbars, tab bars, or floating chrome the system supplies Liquid Glass; use .buttonStyle(.glass) or .buttonStyle(.glassProminent) there instead of .registry styles.

@State private var bold = false
@State private var italic = false

ControlGroup {
    Toggle("Bold", systemImage: "bold", isOn: $bold)
    Toggle("Italic", systemImage: "italic", isOn: $italic)
}
.registryToggleGroup()
```


### validated-input (component 0.1.0)


```swift
@State private var email = ""
@State private var password = ""
@State private var confirmation = ""
@State private var phone = ""
@State private var emailValidity: InputValidity = .empty

ValidatedInput("Email", text: $email, validations: [.required, .email], validity: $emailValidity)
    .keyboardType(.emailAddress)
    .textInputAutocapitalization(.never)

ValidatedInput("Password", text: $password, validations: [.required, .password()], isSecure: true)

ValidatedInput("Confirm password", text: $confirmation, validations: [.required, .matching(password)], isSecure: true)

ValidatedInput("Phone", text: $phone, validations: [.required, .internationalPhone])
    .keyboardType(.phonePad)
```


### transaction-row (component 0.5.1)


```swift
TransactionRow(
    title: Text("Mishmash Bakery"),
    subtitle: Text("Today, 09:41"),
    amount: Text(-8.75, format: .currency(code: "KWD")),
    systemImage: "cup.and.saucer.fill"
)
.registryTone(.negative)
```


## Blocks


### activity-feed (block 0.2.2)


```swift
ActivityFeed(
    "Activity",
    notice: ActivityNotice("Card delivery delayed", message: Text("Arrives Thursday.")),
    onDismissNotice: { },
    items: [
        ActivityItem(
            id: "bakery",
            title: Text("Mishmash Bakery"),
            detail: Text("Card payment of KWD 8.750"),
            timestamp: Text("09:41"),
            initials: "MB",
            senderName: Text("Mishmash Bakery"),
            isUnread: true
        )
    ],
    earlierItems: [],
    isLoading: false,
    onSelect: { id in }
)
```


### auth-form (block 0.3.2)


```swift
AuthForm(
    "Welcome back",
    identity: $email,
    identityError: emailError,
    password: $password,
    passwordError: passwordError,
    formError: formError,
    isSubmitting: isSubmitting,
    secondaryActionTitle: "Forgot password?",
    onSecondaryAction: { },
    onSubmit: { }
)
```


### command-search (block 0.2.1)


```swift
@State private var query = ""

CommandSearch(
    "Search",
    query: $query,
    prompt: "Search actions and activity",
    sections: sections,
    emptyDescription: Text("Try a payee, a card, or an action."),
    shortcuts: [
        CommandShortcutHint("Open search", keys: "⌘K", keysLabel: Text("Command K"))
    ],
    onSelect: { id in }
)
```


### dashboard (block 0.1.1)


```swift
Dashboard(
    "Analytics",
    metrics: [
        DashboardMetric(
            title: "Revenue",
            value: Text(48_200, format: .currency(code: "USD")),
            detail: Text("Up 12% this month"),
            systemImage: "dollarsign.circle.fill"
        )
    ],
    chartTitle: "Visitors by channel",
    points: [
        DashboardSeriesPoint(id: "jan-direct", category: "Jan", series: "Direct", value: 186)
    ],
    tableTitle: "Recent invoices",
    rows: [
        DashboardRow(
            id: "1041",
            title: Text("Invoice 1041"),
            detail: Text("Northwind Trading"),
            status: Text("Paid"),
            amount: Text(1_240, format: .currency(code: "USD"))
        )
    ],
    onSelect: { id in }
)
```


### finance-overview (block 0.4.3)


```swift
FinanceOverview(
    "Overview",
    balanceTitle: "Available balance",
    balance: Text(12_480.32, format: .currency(code: "USD")),
    changeTitle: "Monthly change",
    change: Text(0.082, format: .percent),
    sectionTitle: "Recent activity",
    transactions: [
        FinanceTransactionItem(
            id: "salary",
            title: Text("Salary"),
            subtitle: Text("Yesterday"),
            amount: Text(2_450, format: .currency(code: "KWD")),
            systemImage: "building.columns.fill",
            tone: .positive
        )
    ],
    onSelect: { id in }
)
```


### nutrition-overview (block 0.2.3)


```swift
NutritionOverview(
    "Today",
    energyTitle: "Energy",
    energy: Text("1,640 kcal"),
    energyDetail: Text("360 kcal remaining"),
    sectionTitle: "Macronutrients",
    macros: [
        NutritionMacroItem(
            id: "protein",
            name: "Protein",
            value: Text("96 g"),
            target: Text("130 g"),
            progress: 96.0 / 130.0,
            systemImage: "fish.fill",
            tint: .indigo
        )
    ],
    actionTitle: "Log food",
    onLogFood: {}
)
```


### preview (block 0.3.1)


```swift
PreviewWall()
```


### preview-02 (block 0.3.1)


```swift
PreviewWall02()
```


### questionnaire (block 0.1.1)


```swift
@State private var currentStep = 0
@State private var answers: [String: QuestionnaireAnswer] = [:]

Questionnaire(
    "Set up your profile",
    steps: [
        QuestionnaireStep(
            id: "goal",
            title: "What is your main goal?",
            kind: .singleChoice([
                QuestionnaireOption(id: "save", title: "Save more"),
                QuestionnaireOption(id: "invest", title: "Start investing")
            ])
        )
    ],
    currentStep: $currentStep,
    answers: $answers,
    onFinish: { }
)
```


### settings-section (block 0.1.2)


```swift
SettingsSection(
    "Notifications",
    footer: Text("Quiet hours apply to every channel.")
) {
    Toggle("Transaction alerts", isOn: $alertsEnabled)
        .settingsRowDescription(Text("A push notification for every card transaction."))

    Toggle("Marketing messages", isOn: $marketingEnabled)
        .settingsRowDisabled(
            !marketingAllowed,
            explanation: Text("Managed by your organization's privacy policy.")
        )

    LabeledContent("Currency") {
        Picker("Currency", selection: $currency) {
            Text("Kuwaiti dinar").tag("KWD")
            Text("US dollar").tag("USD")
        }
        .registrySelect()
    }

    Button("Sign out", role: .destructive) { }
        .buttonStyle(.registry)
}
```


### signup-form (block 0.1.1)


```swift
SignUpForm(
    "Create your account",
    name: $name,
    nameError: nameError,
    email: $email,
    emailError: emailError,
    password: $password,
    passwordError: passwordError,
    confirmation: $confirmation,
    confirmationError: confirmationError,
    acceptsTerms: $acceptsTerms,
    termsError: termsError,
    formError: formError,
    isSubmitting: isSubmitting,
    secondaryActionTitle: "Already have an account?",
    onSecondaryAction: { },
    onSubmit: { }
)
```


## Recipes


### alert-dialog (recipe 0.1.1)


```swift
@State private var isConfirmingSignOut = false

Button("Sign out", role: .destructive) {
    isConfirmingSignOut = true
}
.alert("Sign out?", isPresented: $isConfirmingSignOut) {
    Button("Sign out", role: .destructive) { }
    Button("Cancel", role: .cancel) { }
} message: {
    Text("You will need your password to sign in again.")
}
.registryItem("alert-dialog")
```


### aspect-ratio (recipe 0.3.1)


```swift
Color.indigo
    .overlay {
        Image(systemName: "play.fill")
            .foregroundStyle(.white)
            .accessibilityHidden(true)
    }
    .aspectRatio(16.0 / 9.0, contentMode: .fit)
    .accessibilityLabel("Video placeholder")
    .registryItem("aspect-ratio")

Color.teal
    .aspectRatio(1, contentMode: .fit)
    .frame(maxWidth: 160)
    .accessibilityLabel("Avatar placeholder")
```


### calendar (recipe 0.1.1)


```swift
@State private var date = Date.now
@State private var dates: Set<DateComponents> = []

DatePicker("Statement date", selection: $date, displayedComponents: .date)
    .datePickerStyle(.graphical)
    .registryItem("calendar")

MultiDatePicker("Reminder days", selection: $dates)
```


### carousel (recipe 0.1.1)


```swift
ScrollView(.horizontal) {
    HStack(spacing: 12) {
        ForEach(cards) { card in
            VStack(alignment: .leading, spacing: 8) {
                Label(card.title, systemImage: card.systemImage)
                    .font(.subheadline.weight(.semibold))
                Text(card.amount, format: .currency(code: "KWD"))
                    .font(.title.monospacedDigit())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .registrySurface()
            .containerRelativeFrame(.horizontal)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(card.title) card")
        }
    }
    .scrollTargetLayout()
}
.scrollTargetBehavior(.paging)
.registryItem("carousel")
```


### chart-tooltip (recipe 0.1.1)


```swift
@State private var selectedMonth: String?

var selected: MonthlyBalance? {
    balances.first { $0.month == selectedMonth }
}

Chart {
    ForEach(balances) { row in
        BarMark(
            x: .value("Month", row.month),
            y: .value("Balance", row.amount)
        )
        .foregroundStyle(TintShapeStyle())
    }
    if let selected {
        RuleMark(x: .value("Month", selected.month))
            .foregroundStyle(.secondary)
            .annotation(position: .top) {
                Text(selected.amount, format: .currency(code: "KWD"))
                    .font(.footnote.monospacedDigit())
                    .padding(6)
                    .registrySurface()
            }
    }
}
.chartXSelection(value: $selectedMonth)
.registryChart()
.registryItem("chart-tooltip")
```


### collapsible (recipe 0.1.1)


```swift
@State private var isShowingDetails = false

DisclosureGroup("Fee breakdown", isExpanded: $isShowingDetails) {
    LabeledContent("Transfer fee", value: "KWD 1.000")
    LabeledContent("Exchange margin", value: "KWD 0.450")
}
.registryItem("collapsible")
```


### context-menu (recipe 0.1.2)


```swift
TransactionRow(
    title: Text("Mishmash Bakery"),
    subtitle: Text("Today, 09:41"),
    amount: Text(-8.75, format: .currency(code: "KWD")),
    systemImage: "cup.and.saucer.fill"
)
.registryTone(.negative)
.contextMenu {
    Button("Add note", systemImage: "square.and.pencil") { }
    Button("Share", systemImage: "square.and.arrow.up") { }
    Divider()
    Button("Report", systemImage: "flag", role: .destructive) { }
}
.registryItem("context-menu")
```


### date-picker (recipe 0.1.1)


```swift
@State private var date = Date.now

DatePicker("Statement date", selection: $date, in: range, displayedComponents: .date)
    .datePickerStyle(.compact)
    .registryItem("date-picker")

Menu("Presets") {
    Button("Today") { date = .now }
    Button("Tomorrow") { date = .now.addingTimeInterval(60 * 60 * 24) }
    Button("Next week") { date = .now.addingTimeInterval(60 * 60 * 24 * 7) }
}
.accessibilityLabel("Date presets")
```


### dialog (recipe 0.1.1)


```swift
@State private var isEditing = false

Button("Edit profile") { isEditing = true }
    .sheet(isPresented: $isEditing) {
        NavigationStack {
            ProfileEditor()
                .navigationTitle("Edit profile")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { isEditing = false }
                    }
                }
        }
    }
    .registryItem("dialog")
```


### direction (recipe 0.3.1)


```swift
@Environment(\.layoutDirection) private var layoutDirection

HStack {
    Image(systemName: "person.crop.circle")
        .accessibilityHidden(true)
    Text("Account")
    Spacer()
    Image(systemName: "chevron.forward")
        .accessibilityHidden(true)
}
.registryItem("direction")
```


### drawer (recipe 0.1.1)


```swift
@State private var isShowingFilters = false

Button("Filters") { isShowingFilters = true }
    .sheet(isPresented: $isShowingFilters) {
        FilterOptions()
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
    }
    .registryItem("drawer")
```


### dropdown-menu (recipe 0.1.1)


```swift
@State private var sort = "recent"

Menu("Sort", systemImage: "arrow.up.arrow.down") {
    Picker("Sort by", selection: $sort) {
        Text("Most recent").tag("recent")
        Text("Amount").tag("amount")
    }
    Divider()
    Button("Export", systemImage: "square.and.arrow.up") { }
}
.buttonStyle(.registryOutline)
.registryItem("dropdown-menu")
```


### input-otp (recipe 0.1.1)


```swift
@State private var code = ""

TextField("One-time code", text: $code)
    .textContentType(.oneTimeCode)
    .keyboardType(.numberPad)
    .textFieldStyle(.registryInput)
    .font(.title2.monospacedDigit())
    .accessibilityLabel("Verification code")
    .onChange(of: code) { _, newValue in
        code = String(newValue.filter(\.isNumber).prefix(6))
    }
    .registryItem("input-otp")

Button("Verify") { }
    .buttonStyle(.registry)
    .disabled(code.count < 6)
```


### menubar (recipe 0.1.0)


```swift
WindowGroup {
    RootView()
}
.commands {
    CommandMenu("Account") {
        Button("Sign Out") { }
            .keyboardShortcut("q", modifiers: [.command, .shift])
    }
}
```


### native-select (recipe 0.3.1)


```swift
@State private var sort = "recent"

Picker("Sort", selection: $sort) {
    Text("Most recent").tag("recent")
    Text("Oldest").tag("oldest")
    Text("Amount").tag("amount")
}
.pickerStyle(.menu)
.registryItem("native-select")
```


### popover (recipe 0.1.1)


```swift
@State private var isShowingHelp = false

Button("Why is this needed?") { isShowingHelp = true }
    .buttonStyle(.registryLink)
    .popover(isPresented: $isShowingHelp) {
        Text("We use your date of birth to verify your identity.")
            .padding()
            .presentationCompactAdaptation(.popover)
    }
    .registryItem("popover")
```


### radio-group (recipe 0.3.1)


```swift
@State private var selection = "standard"

Picker("Delivery speed", selection: $selection) {
    Text("Standard").tag("standard")
    Text("Express").tag("express")
    Text("Same day").tag("same-day")
}
.pickerStyle(.inline)
.registryItem("radio-group")
```


### scroll-area (recipe 0.2.1)


```swift
ScrollView {
    FinanceOverview(
        "Overview",
        balanceTitle: "Available balance",
        balance: Text(12_480.32, format: .currency(code: "USD")),
        changeTitle: "Monthly change",
        change: Text(0.082, format: .percent),
        sectionTitle: "Recent activity",
        transactions: rows,
        onSelect: { id in }
    )
}
.contentMargins(.horizontal, 16, for: .scrollContent)
.scrollIndicators(.hidden)
.scrollClipDisabled()
.scrollEdgeEffectStyle(.soft, for: .top)
.registryItem("scroll-area")
```


### sheet (recipe 0.1.1)


```swift
@State private var isShowingDetails = false

NavigationStack {
    List {
        LabeledContent("Merchant", value: "Mishmash Bakery")
        LabeledContent("Amount", value: "KWD 8.750")
    }
    .navigationTitle("Transaction")
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Details", systemImage: "sidebar.trailing") {
                isShowingDetails.toggle()
            }
            .accessibilityLabel("Toggle details")
        }
    }
    .inspector(isPresented: $isShowingDetails) {
        List {
            LabeledContent("Category", value: "Dining")
            LabeledContent("Card", value: "Visa 4321")
            LabeledContent("Status", value: "Cleared")
        }
        .inspectorColumnWidth(min: 240, ideal: 280, max: 360)
    }
}
.registryItem("sheet")
```


### sidebar (recipe 0.3.1)


```swift
@State private var selection: String? = "activity"
@State private var tab = "activity"

NavigationSplitView {
    List(selection: $selection) {
        Label("Activity", systemImage: "bell").tag("activity")
        Label("Cards", systemImage: "creditcard").tag("cards")
    }
    .navigationTitle("Bank")
    .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
} detail: {
    // A visually rich detail extends under the sidebar instead of stopping at its edge
    ActivityBanner()
        .backgroundExtensionEffect()
    if selection == "activity" { ActivityScreen() } else { CardsScreen() }
}
.registryItem("sidebar")

// The HIG's first choice on iPad: a tab bar people can switch to a sidebar
TabView(selection: $tab) {
    Tab("Activity", systemImage: "bell", value: "activity") { ActivityScreen() }
    Tab("Cards", systemImage: "creditcard", value: "cards") { CardsScreen() }
}
.tabViewStyle(.sidebarAdaptable)
```


### slider (recipe 0.3.1)


```swift
@State private var volume = 64.0

Slider(value: $volume, in: 0...100, step: 1) {
    Text("Volume")
} minimumValueLabel: {
    Image(systemName: "speaker.fill")
        .accessibilityHidden(true)
} maximumValueLabel: {
    Image(systemName: "speaker.wave.3.fill")
        .accessibilityHidden(true)
}
.controlSize(.large)
.registryItem("slider")
```


### switch (recipe 0.3.1)


```swift
@State private var notifications = true

Toggle("Notifications", isOn: $notifications)
    .toggleStyle(.switch)
    .registryItem("switch")
```


### tabs (recipe 0.3.1)


```swift
@State private var selection = "overview"

Picker("Section", selection: $selection) {
    Text("Overview").tag("overview")
    Text("Activity").tag("activity")
    Text("Settings").tag("settings")
}
.pickerStyle(.segmented)
.registryItem("tabs")
```


### tooltip (recipe 0.1.1)


```swift
Button("Freeze card", systemImage: "snowflake") { }
    .buttonStyle(.registryOutline)
    .accessibilityHint("Blocks new purchases until you unfreeze the card.")
    .help("Blocks new purchases until you unfreeze the card.")
    .registryItem("tooltip")
```


### typography (recipe 0.1.1)


```swift
VStack(alignment: .leading, spacing: 8) {
    Text("Balance")
        .font(.title2.weight(.semibold))
    Text(amount, format: .currency(code: "KWD"))
        .font(.largeTitle)
        .monospacedDigit()
    Text("Updated today")
        .font(.footnote)
        .foregroundStyle(.secondary)
}
.fontDesign(.rounded)
.registryItem("typography")
```
