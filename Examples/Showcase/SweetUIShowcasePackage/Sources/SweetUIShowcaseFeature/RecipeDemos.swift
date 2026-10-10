import SwiftUI
import SweetUIFoundations

// Each recipe demo compiles the recipe's `usage` snippet verbatim, so a snippet
// that stops compiling against the SDK fails the Showcase build.

struct AspectRatioRecipe: View {
    var body: some View {
        DemoSurface {
            Color.indigo
                .overlay {
                    Image(systemName: "rectangle.inset.filled")
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                }
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityLabel("Sixteen by nine layout example")
                .registryItem("aspect-ratio")
        }
    }
}

struct DirectionRecipe: View {
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        DemoSurface {
            Label("Leading content mirrors automatically", systemImage: "arrow.forward")
                .labelStyle(.registry)
                .registryItem("direction")
            Text(layoutDirection == .rightToLeft ? "Layout direction: right to left" : "Layout direction: left to right")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

struct NativeSelectRecipe: View {
    @State private var sort = "recent"

    var body: some View {
        DemoSurface {
            Picker("Sort", selection: $sort) {
                Text("Most recent").tag("recent")
                Text("Oldest").tag("oldest")
            }
            .pickerStyle(.menu)
            .registryItem("native-select")
        }
    }
}

struct RadioGroupRecipe: View {
    @State private var delivery = "standard"

    var body: some View {
        DemoSurface {
            Picker("Delivery", selection: $delivery) {
                Text("Standard").tag("standard")
                Text("Express").tag("express")
            }
            .pickerStyle(.inline)
            .registryItem("radio-group")
        }
    }
}

struct SliderRecipe: View {
    @State private var volume = 0.64

    var body: some View {
        DemoSurface {
            HStack {
                Label("Volume", systemImage: "speaker.wave.2.fill")
                    .labelStyle(.registry)
                Spacer()
                Text(volume, format: .percent.precision(.fractionLength(0)))
                    .monospacedDigit()
            }
            Slider(value: $volume) {
                Text("Volume")
            }
            .registryItem("slider")
        }
    }
}

struct SwitchRecipe: View {
    @State private var notifications = true

    var body: some View {
        DemoSurface {
            Toggle("Notifications", isOn: $notifications)
                .toggleStyle(.switch)
                .registryItem("switch")
        }
    }
}

struct TabsRecipe: View {
    @State private var selection = "overview"

    var body: some View {
        DemoSurface {
            Picker("Section", selection: $selection) {
                Text("Overview").tag("overview")
                Text("Activity").tag("activity")
                Text("Settings").tag("settings")
            }
            .pickerStyle(.segmented)
            .registryItem("tabs")
        }
    }
}

struct AlertDialogRecipe: View {
    @State private var isConfirmingSignOut = false

    var body: some View {
        DemoSurface {
            Button("Sign out", role: .destructive) {
                isConfirmingSignOut = true
            }
            .buttonStyle(.registry)
            .alert("Sign out?", isPresented: $isConfirmingSignOut) {
                Button("Sign out", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You will need your password to sign in again.")
            }
            .registryItem("alert-dialog")
        }
    }
}

struct CalendarRecipe: View {
    @State private var date = Date.now
    @State private var dates: Set<DateComponents> = []

    var body: some View {
        DemoSurface {
            DatePicker("Statement date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .registryItem("calendar")
            MultiDatePicker("Reminder days", selection: $dates)
        }
    }
}

struct CollapsibleRecipe: View {
    @State private var isShowingDetails = false

    var body: some View {
        DemoSurface {
            DisclosureGroup("Fee breakdown", isExpanded: $isShowingDetails) {
                LabeledContent("Transfer fee", value: "KWD 1.000")
                LabeledContent("Exchange margin", value: "KWD 0.450")
            }
            .registryItem("collapsible")
        }
    }
}

struct ContextMenuRecipe: View {
    var body: some View {
        DemoSurface {
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
            Text("Touch and hold the row.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

struct DialogRecipe: View {
    @State private var isEditing = false

    var body: some View {
        DemoSurface {
            Button("Edit profile") { isEditing = true }
                .buttonStyle(.registryOutline)
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
        }
    }
}

private struct ProfileEditor: View {
    @State private var name = "Maya Khalid"

    var body: some View {
        Form {
            TextField("Name", text: $name)
        }
    }
}

struct DrawerRecipe: View {
    @State private var isShowingFilters = false

    var body: some View {
        DemoSurface {
            Button("Filters") { isShowingFilters = true }
                .buttonStyle(.registryOutline)
                .sheet(isPresented: $isShowingFilters) {
                    FilterOptions()
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
                .registryItem("drawer")
        }
    }
}

private struct FilterOptions: View {
    @State private var showPending = true

    var body: some View {
        Form {
            Toggle("Show pending", isOn: $showPending)
        }
    }
}

struct DropdownMenuRecipe: View {
    @State private var sort = "recent"

    var body: some View {
        DemoSurface {
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
        }
    }
}

struct PopoverRecipe: View {
    @State private var isShowingHelp = false

    var body: some View {
        DemoSurface {
            Button("Why is this needed?") { isShowingHelp = true }
                .buttonStyle(.registryLink)
                .popover(isPresented: $isShowingHelp) {
                    Text("We use your date of birth to verify your identity.")
                        .padding()
                        .presentationCompactAdaptation(.popover)
                }
                .registryItem("popover")
        }
    }
}

struct ScrollAreaRecipe: View {
    private let rows = [
        FinanceTransactionItem(
            id: "salary",
            title: Text("Salary"),
            subtitle: Text("Yesterday"),
            amount: Text(2_450, format: .currency(code: "KWD")),
            systemImage: "building.columns.fill",
            tone: .positive
        )
    ]

    var body: some View {
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
        .frame(height: 420)
        .registrySurface()
        .registryItem("scroll-area")
    }
}

struct SidebarRecipe: View {
    @State private var selection: String? = "activity"
    @State private var tab = "activity"

    var body: some View {
        VStack(spacing: 16) {
            splitView
            // The HIG's first choice on iPad: a tab bar people can switch to a sidebar
            TabView(selection: $tab) {
                Tab("Activity", systemImage: "bell", value: "activity") { ActivityScreen() }
                Tab("Cards", systemImage: "creditcard", value: "cards") { CardsScreen() }
            }
            .tabViewStyle(.sidebarAdaptable)
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .registrySurface()
        }
    }

    private var splitView: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Activity", systemImage: "bell").tag("activity")
                Label("Cards", systemImage: "creditcard").tag("cards")
            }
            .navigationTitle("Bank")
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } detail: {
            VStack(spacing: 0) {
                // A visually rich detail extends under the sidebar instead of stopping at its edge
                ActivityBanner()
                    .backgroundExtensionEffect()
                if selection == "activity" { ActivityScreen() } else { CardsScreen() }
            }
        }
        .frame(height: 360)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .registrySurface()
        .registryItem("sidebar")
    }
}

private struct ActivityBanner: View {
    var body: some View {
        LinearGradient(colors: [.indigo.opacity(0.6), .mint.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
            .frame(height: 96)
            .overlay(alignment: .bottomLeading) {
                Text("Overview")
                    .font(.title2.bold())
                    .padding()
            }
            .accessibilityHidden(true)
    }
}

private struct ActivityScreen: View {
    var body: some View {
        Text("Activity")
            .font(.headline)
    }
}

private struct CardsScreen: View {
    var body: some View {
        Text("Cards")
            .font(.headline)
    }
}

struct TooltipRecipe: View {
    var body: some View {
        DemoSurface {
            Button("Freeze card", systemImage: "snowflake") { }
                .buttonStyle(.registryOutline)
                .accessibilityHint("Blocks new purchases until you unfreeze the card.")
                .help("Blocks new purchases until you unfreeze the card.")
                .registryItem("tooltip")
            Text("VoiceOver reads the hint; a pointer shows the help text.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

struct FoldArrangementRecipe: View {
    var body: some View {
        Group {
            if #available(iOS 27.1, *) {
                ArrangementView {
                    List {
                        LabeledContent("Merchant", value: "Mishmash Bakery")
                        LabeledContent("Amount", value: "KWD 8.750")
                    }
                } secondary: {
                    List {
                        LabeledContent("Category", value: "Dining")
                        LabeledContent("Status", value: "Cleared")
                    }
                }
                .arrangementViewStyle(.split)
            } else {
                Text("ArrangementView needs iOS 27.1.")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 360)
        .registrySurface()
        .registryItem("fold-arrangement")
    }
}
