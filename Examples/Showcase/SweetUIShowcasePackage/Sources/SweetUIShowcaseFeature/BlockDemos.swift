import Foundation
import SwiftUI
import SweetUIFoundations

// Harness state for the installed blocks. Validation, fake submission, and
// loading toggles live here in the consumer, never inside the blocks.

struct FinanceDemo: View {
    var body: some View {
        FinanceOverview(
            "Overview",
            balanceTitle: "Available balance",
            balance: Text(12_480.32, format: .currency(code: "USD")),
            changeTitle: "Monthly change",
            change: Text(0.082, format: .percent.precision(.fractionLength(1))),
            sectionTitle: "Recent activity",
            transactions: transactions,
            emptyDescription: Text("New transactions will appear here."),
            onSelect: { _ in }
        )
    }

    private var transactions: [FinanceTransactionItem<String>] {
        guard !LaunchArguments.current.contains("-empty-finance") else {
            return []
        }
        return [
            FinanceTransactionItem(
                id: "bakery",
                title: Text("Mishmash Bakery"),
                subtitle: Text("Today, 09:41"),
                amount: Text(-8.75, format: .currency(code: "KWD")),
                systemImage: "cup.and.saucer.fill",
                tone: .negative
            ),
            FinanceTransactionItem(
                id: "salary",
                title: Text("Salary"),
                subtitle: Text("Yesterday"),
                amount: Text(2_450, format: .currency(code: "KWD")),
                systemImage: "building.columns.fill",
                tone: .positive
            ),
            FinanceTransactionItem(
                id: "mobile",
                title: Text("Mobile service"),
                subtitle: Text("Monday"),
                amount: Text(-18, format: .currency(code: "KWD")),
                systemImage: "antenna.radiowaves.left.and.right",
                tone: .negative
            )
        ]
    }
}

struct NutritionDemo: View {
    var body: some View {
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
                ),
                NutritionMacroItem(
                    id: "carbs",
                    name: "Carbohydrates",
                    value: Text("182 g"),
                    target: Text("240 g"),
                    progress: 182.0 / 240.0,
                    systemImage: "leaf.fill",
                    tint: .green
                ),
                NutritionMacroItem(
                    id: "fat",
                    name: "Fat",
                    value: Text("48 g"),
                    target: Text("65 g"),
                    progress: 48.0 / 65.0,
                    systemImage: "drop.fill",
                    tint: .orange
                )
            ],
            actionTitle: "Log food",
            onLogFood: {}
        )
    }
}

/// Local validation and a fake submit that flips `isSubmitting` and then
/// reports a form error, so UI tests can exercise validation and disabled
/// states deterministically without networking.
struct AuthenticationDemo: View {
    @State private var email = ""
    @State private var password = ""
    @State private var emailError: LocalizedStringResource?
    @State private var passwordError: LocalizedStringResource?
    @State private var formError: LocalizedStringResource?
    @State private var isSubmitting = false

    var body: some View {
        AuthForm(
            "Welcome back",
            identity: $email,
            identityError: emailError,
            password: $password,
            passwordError: passwordError,
            formError: formError,
            isSubmitting: isSubmitting,
            secondaryActionTitle: "Forgot password?",
            onSecondaryAction: {},
            onSubmit: submit
        )
        // The fake submission is a task tied to the view, so it is cancelled
        // if the screen goes away mid-flight instead of writing into it.
        .task(id: isSubmitting) {
            guard isSubmitting else { return }
            // Two seconds keeps the submitting window long enough for the UI
            // tests to observe the disabled controls deterministically.
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }
            isSubmitting = false
            formError = "We could not sign you in. Try again."
        }
    }

    private func submit() {
        emailError = email.contains("@") ? nil : "Enter a valid email address"
        passwordError = password.isEmpty ? "Enter your password" : nil
        formError = nil
        guard emailError == nil, passwordError == nil else { return }
        isSubmitting = true
    }
}

/// Caller-owned toggle and selection bindings, one organization-managed
/// disabled row, and a destructive sign-out action. The captions under the
/// section mirror the bindings so UI tests can prove control writes flow
/// through caller state.
struct SettingsDemo: View {
    @State private var alertsEnabled = true
    @State private var summaryEnabled = false
    @State private var marketingEnabled = false
    @State private var currency = "KWD"
    @State private var didSignOut = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection(
                "Notifications",
                footer: Text("Quiet hours apply to every channel.")
            ) {
                Toggle("Transaction alerts", isOn: $alertsEnabled)
                    .settingsRowDescription(
                        Text("A push notification for every card transaction.")
                    )

                Toggle("Weekly summary", isOn: $summaryEnabled)

                Toggle("Marketing messages", isOn: $marketingEnabled)
                    .settingsRowDisabled(
                        explanation: Text("Managed by your organization's privacy policy.")
                    )

                LabeledContent("Currency") {
                    Picker("Currency", selection: $currency) {
                        Text("Kuwaiti dinar").tag("KWD")
                        Text("US dollar").tag("USD")
                    }
                    .registrySelect()
                }

                Button(role: .destructive) {
                    didSignOut = true
                } label: {
                    Text("Sign out")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.registry)
            }

            Text(
                alertsEnabled
                    ? "Transaction alerts are on."
                    : "Transaction alerts are off."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)

            if didSignOut {
                Text("Signed out.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Caller-owned feed state with a picker to switch between loaded, loading,
/// and empty so every Stage 3 state is reachable in one screen; the capture
/// launch shows the loaded state.
struct ActivityFeedDemo: View {
    enum FeedState: String, CaseIterable, Identifiable {
        case loaded, loading, empty
        var id: String { rawValue }
    }

    @State private var state: FeedState = .loaded
    @State private var noticeDismissed = false
    @State private var selected: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Feed state", selection: $state) {
                ForEach(FeedState.allCases) { state in
                    Text(state.rawValue.capitalized).tag(state)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("activity.state")

            ActivityFeed(
                "Activity",
                notice: noticeDismissed || state == .empty
                    ? nil
                    : ActivityNotice(
                        "Card delivery delayed",
                        message: Text("Your new card now arrives on Thursday.")
                    ),
                onDismissNotice: { noticeDismissed = true },
                items: state == .empty ? [] : items,
                earlierItems: state == .empty ? [] : earlierItems,
                isLoading: state == .loading,
                emptyDescription: Text("New activity will appear here."),
                onSelect: { selected = $0 }
            )

            if let selected {
                Text("Selected \(selected).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var items: [ActivityItem<String>] {
        [
            ActivityItem(
                id: "bakery",
                title: Text("Mishmash Bakery"),
                detail: Text("Card payment of KWD 8.750"),
                timestamp: Text("09:41"),
                initials: "MB",
                senderName: Text("Mishmash Bakery"),
                isUnread: true
            ),
            ActivityItem(
                id: "salary",
                title: Text("Salary received"),
                detail: Text("KWD 2,450.000 from Harbor Bank"),
                timestamp: Text("Yesterday"),
                initials: "HB",
                senderName: Text("Harbor Bank")
            ),
            ActivityItem(
                id: "statement",
                title: Text("Statement ready"),
                detail: Text("August 2026"),
                timestamp: Text("Monday"),
                initials: "ST",
                senderName: Text("Statements")
            )
        ]
    }

    private var earlierItems: [ActivityItem<String>] {
        [
            ActivityItem(
                id: "mobile",
                title: Text("Mobile service"),
                detail: Text("Card payment of KWD 18.000"),
                timestamp: Text("28 Aug"),
                initials: "MS",
                senderName: Text("Mobile service")
            )
        ]
    }
}

/// Caller-owned query and filtering for the command-search block; the caption
/// under the screen reports the selection so UI tests can prove it.
struct CommandSearchDemo: View {
    @State private var query = ""
    @State private var selected: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CommandSearch(
                "Search",
                query: $query,
                prompt: "Search actions and activity",
                sections: DemoCommands.sections(matching: query),
                emptyDescription: Text("Try a payee, a card, or an action."),
                shortcuts: [
                    CommandShortcutHint("Open search", keys: "⌘K", keysLabel: Text("Command K")),
                    CommandShortcutHint("Run the highlighted command", keys: "↩", keysLabel: Text("Return")),
                ],
                onSelect: { selected = $0 }
            )

            if let selected {
                Text("Ran \(selected).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Caller-owned step index and answers for the questionnaire block. Four steps
/// exercise every kind: a single choice, a multiple choice, a skippable
/// freeform, and a final single choice. On finish the demo renders a summary of
/// the collected answers so UI tests can prove answers flow through caller state.
struct QuestionnaireDemo: View {
    @State private var currentStep = 0
    @State private var answers: [String: QuestionnaireAnswer] = [:]
    @State private var didFinish = false

    private let steps: [QuestionnaireStep] = [
        QuestionnaireStep(
            id: "goal",
            title: "What is your main goal?",
            description: "Pick the one that fits best.",
            kind: .singleChoice([
                QuestionnaireOption(id: "save", title: "Save more"),
                QuestionnaireOption(id: "invest", title: "Start investing"),
                QuestionnaireOption(id: "budget", title: "Stick to a budget"),
            ])
        ),
        QuestionnaireStep(
            id: "interests",
            title: "Which topics interest you?",
            description: "Choose any that apply.",
            kind: .multipleChoice([
                QuestionnaireOption(id: "cards", title: "Cards and payments"),
                QuestionnaireOption(id: "savings", title: "Savings accounts"),
                QuestionnaireOption(id: "loans", title: "Financing"),
            ])
        ),
        QuestionnaireStep(
            id: "notes",
            title: "Anything else?",
            kind: .freeform(prompt: "Tell us what matters to you"),
            isSkippable: true
        ),
        QuestionnaireStep(
            id: "contact",
            title: "How should we reach you?",
            kind: .singleChoice([
                QuestionnaireOption(id: "email", title: "Email"),
                QuestionnaireOption(id: "sms", title: "Text message"),
            ])
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Questionnaire(
                "Set up your profile",
                steps: steps,
                currentStep: $currentStep,
                answers: $answers,
                onFinish: { didFinish = true }
            )

            if didFinish {
                Text("Answers: \(summary)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var summary: String {
        steps.compactMap { step in
            switch answers[step.id] {
            case .single(let id):
                return "\(step.id)=\(id)"
            case .multiple(let ids):
                return "\(step.id)=\(ids.sorted().joined(separator: ","))"
            case .freeform(let text):
                return text.isEmpty ? nil : "\(step.id)=\(text)"
            case nil:
                return nil
            }
        }
        .joined(separator: "; ")
    }
}

/// The theme preview wall. The capture route wraps it in a scroll view, so the
/// demo is the block itself with no chrome of its own.
struct PreviewDemo: View {
    var body: some View {
        PreviewWall()
    }
}

/// The second theme preview wall. The capture route wraps it in a scroll view,
/// so the demo is the block itself with no chrome of its own.
struct Preview02Demo: View {
    var body: some View {
        PreviewWall02()
    }
}

/// Realistic neutral analytics data with no real brands, and a caller-owned
/// selection action so the invoice titles are selectable at the call site.
struct DashboardDemo: View {
    var body: some View {
        Dashboard(
            "Analytics",
            metrics: metrics,
            chartTitle: "Visitors by channel",
            points: points,
            tableTitle: "Recent invoices",
            rows: rows,
            onSelect: { _ in }
        )
    }

    private var metrics: [DashboardMetric] {
        [
            DashboardMetric(
                title: "Revenue",
                value: Text(48_200, format: .currency(code: "USD")),
                detail: Text("Up 12% this month"),
                systemImage: "dollarsign.circle.fill"
            ),
            DashboardMetric(
                title: "Active users",
                value: Text(3_182, format: .number),
                detail: Text("Up 4% this week"),
                systemImage: "person.2.fill"
            ),
            DashboardMetric(
                title: "Conversion",
                value: Text(0.061, format: .percent.precision(.fractionLength(1))),
                systemImage: "chart.line.uptrend.xyaxis"
            )
        ]
    }

    private var points: [DashboardSeriesPoint] {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
        let direct: [Double] = [186, 205, 237, 173, 209, 264]
        let referral: [Double] = [80, 130, 120, 190, 150, 172]
        var result: [DashboardSeriesPoint] = []
        for (index, month) in months.enumerated() {
            result.append(
                DashboardSeriesPoint(id: "\(month)-direct", category: month, series: "Direct", value: direct[index])
            )
            result.append(
                DashboardSeriesPoint(id: "\(month)-referral", category: month, series: "Referral", value: referral[index])
            )
        }
        return result
    }

    private var rows: [DashboardRow<String>] {
        [
            DashboardRow(
                id: "1041",
                title: Text("Invoice 1041"),
                detail: Text("Northwind Trading"),
                status: Text("Paid"),
                amount: Text(1_240, format: .currency(code: "USD"))
            ),
            DashboardRow(
                id: "1042",
                title: Text("Invoice 1042"),
                detail: Text("Harbor Logistics"),
                status: Text("Pending"),
                amount: Text(880, format: .currency(code: "USD"))
            ),
            DashboardRow(
                id: "1043",
                title: Text("Invoice 1043"),
                detail: Text("Meridian Studio"),
                status: Text("Paid"),
                amount: Text(2_150, format: .currency(code: "USD"))
            ),
            DashboardRow(
                id: "1044",
                title: Text("Invoice 1044"),
                detail: Text("Cedar Supply"),
                status: Text("Overdue"),
                amount: Text(430, format: .currency(code: "USD"))
            ),
            DashboardRow(
                id: "1045",
                title: Text("Invoice 1045"),
                detail: Text("Atlas Freight"),
                status: Text("Pending"),
                amount: Text(1_675, format: .currency(code: "USD"))
            )
        ]
    }
}

/// Local validation and a fake submit that flips `isSubmitting` and then reports
/// a form error, so UI tests can exercise validation and disabled states
/// deterministically without networking.
struct SignUpDemo: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var acceptsTerms = false
    @State private var nameError: LocalizedStringResource?
    @State private var emailError: LocalizedStringResource?
    @State private var passwordError: LocalizedStringResource?
    @State private var confirmationError: LocalizedStringResource?
    @State private var termsError: LocalizedStringResource?
    @State private var formError: LocalizedStringResource?
    @State private var isSubmitting = false

    var body: some View {
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
            onSecondaryAction: {},
            onSubmit: submit
        )
        // The fake submission is a task tied to the view, so it is cancelled
        // if the screen goes away mid-flight instead of writing into it.
        .task(id: isSubmitting) {
            guard isSubmitting else { return }
            // Two seconds keeps the submitting window long enough for the UI
            // tests to observe the disabled controls deterministically.
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }
            isSubmitting = false
            formError = "We could not create your account. Try again."
        }
    }

    private func submit() {
        nameError = name.isEmpty ? "Enter your name" : nil
        emailError = email.contains("@") ? nil : "Enter a valid email address"
        passwordError = password.count >= 8 ? nil : "Use at least 8 characters"
        confirmationError = confirmation == password && !confirmation.isEmpty
            ? nil
            : "Passwords do not match"
        termsError = acceptsTerms ? nil : "Accept the terms to continue"
        formError = nil
        guard nameError == nil,
              emailError == nil,
              passwordError == nil,
              confirmationError == nil,
              termsError == nil
        else { return }
        isSubmitting = true
    }
}
