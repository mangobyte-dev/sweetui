import Charts
import SwiftUI
import SweetUIFoundations

// Each recipe demo compiles the recipe's `usage` snippet against the SDK, so a
// snippet that stops compiling fails the Showcase build. These cover the Stage 7
// slice 3 parity recipes.

struct CarouselRecipe: View {
    private struct Card: Identifiable {
        let id = UUID()
        let title: String
        let amount: Double
        let systemImage: String
    }

    private let cards = [
        Card(title: "Current account", amount: 3_120.50, systemImage: "banknote.fill"),
        Card(title: "Savings", amount: 8_940.00, systemImage: "chart.line.uptrend.xyaxis"),
        Card(title: "Travel card", amount: 420.75, systemImage: "airplane"),
    ]

    var body: some View {
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
        .frame(height: 200)
        .registryItem("carousel")
    }
}

struct DatePickerRecipe: View {
    @State private var date = Date.now

    private let range: ClosedRange<Date> = {
        let now = Date.now
        return now.addingTimeInterval(-60 * 60 * 24) ... now.addingTimeInterval(60 * 60 * 24 * 365)
    }()

    var body: some View {
        DemoSurface {
            HStack {
                DatePicker("Statement date", selection: $date, in: range, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .registryItem("date-picker")
                Spacer()
                Menu("Presets") {
                    Button("Today") { date = .now }
                    Button("Tomorrow") { date = .now.addingTimeInterval(60 * 60 * 24) }
                    Button("Next week") { date = .now.addingTimeInterval(60 * 60 * 24 * 7) }
                }
                .accessibilityLabel("Date presets")
            }
        }
    }
}

struct InputOTPRecipe: View {
    @State private var code = ""

    var body: some View {
        DemoSurface {
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
        }
    }
}

struct MenubarRecipe: View {
    var body: some View {
        NavigationStack {
            DemoSurface {
                Text("A scene-level commands block places these in the iPadOS and macOS menu bar; iPhone shows them here as a toolbar menu.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Account")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Account") {
                        Button("Sign Out") { }
                            .keyboardShortcut("q", modifiers: [.command, .shift])
                    }
                    .accessibilityLabel("Account menu")
                }
            }
        }
        .frame(height: 320)
        .registrySurface()
    }
}

struct SheetRecipe: View {
    @State private var isShowingDetails = false

    var body: some View {
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
        .frame(height: 360)
        .registrySurface()
        .registryItem("sheet")
    }
}

struct TypographyRecipe: View {
    @State private var design: Font.Design = .default

    private let styles: [(name: String, font: Font)] = [
        ("Large Title", .largeTitle),
        ("Title", .title),
        ("Title 2", .title2),
        ("Title 3", .title3),
        ("Headline", .headline),
        ("Subheadline", .subheadline),
        ("Body", .body),
        ("Callout", .callout),
        ("Footnote", .footnote),
        ("Caption", .caption),
        ("Caption 2", .caption2),
    ]

    var body: some View {
        DemoSurface {
            Picker("Font design", selection: $design) {
                Text("Default").tag(Font.Design.default)
                Text("Rounded").tag(Font.Design.rounded)
                Text("Serif").tag(Font.Design.serif)
                Text("Monospaced").tag(Font.Design.monospaced)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Font design")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(styles, id: \.name) { style in
                    Text(style.name)
                        .font(style.font)
                }
            }
            .fontDesign(design)
            .registryItem("typography")
        }
    }
}

private struct MonthlyBalancePoint: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
}

struct ChartTooltipRecipe: View {
    // Starts selected so the capture route shows the annotation the recipe exists for.
    @State private var selectedMonth: String? = "Mar"

    private let balances = [
        MonthlyBalancePoint(month: "Jan", amount: 2.1),
        MonthlyBalancePoint(month: "Feb", amount: 2.6),
        MonthlyBalancePoint(month: "Mar", amount: 2.4),
        MonthlyBalancePoint(month: "Apr", amount: 3.1),
        MonthlyBalancePoint(month: "May", amount: 3.5),
    ]

    private var selected: MonthlyBalancePoint? {
        balances.first { $0.month == selectedMonth }
    }

    var body: some View {
        DemoSurface {
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
            .frame(height: 200)
            .registryItem("chart-tooltip")

            Text(selectedMonth.map { "Selected: \($0)" } ?? "Tap a bar to select a month.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

/// Compiles the menubar recipe's scene-level usage snippet, which cannot live in
/// a view demo because `commands` is a Scene modifier; nothing instantiates it.
private struct MenubarCommandsScene: Scene {
    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
        .commands {
            CommandMenu("Account") {
                Button("Sign Out") { }
                    .keyboardShortcut("q", modifiers: [.command, .shift])
            }
        }
    }
}
