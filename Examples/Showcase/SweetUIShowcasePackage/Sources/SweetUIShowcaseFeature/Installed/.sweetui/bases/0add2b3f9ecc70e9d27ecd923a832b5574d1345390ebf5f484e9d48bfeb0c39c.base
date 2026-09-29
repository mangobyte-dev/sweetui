import SwiftUI
import SweetUIFoundations

/// An FAQ card, translated from shadcn's faq: a segmented topic picker over an
/// accordion of questions, and two footer actions. shadcn uses its tabs and
/// accordion primitives; this pairs a native segmented Picker with registry
/// DisclosureGroups wearing the accordion style, both kept visible at the call
/// site. The copy is neutral, so the card names no third-party brand.
public struct Faq: View {
    @Environment(\.registryTheme) private var theme
    @State private var topic: Topic = .general

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Picker("Topic", selection: $topic) {
                    ForEach(Topic.allCases) { topic in
                        Text(topic.title).tag(topic)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("FAQ topic")

                QuestionList(questions: topic.questions)
                    .id(topic)

                HStack(spacing: theme.metrics.compactSpacing) {
                    Button("Contact support") {}
                        .buttonStyle(.registryOutline)
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                    Button("Learn more") {}
                        .buttonStyle(.registryLink)
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                }
            }
        } label: {
            Text("Help & FAQ")
        }
        .groupBoxStyle(.registryCard)
    }

    private struct QuestionList: View {
        @Environment(\.registryTheme) private var theme
        let questions: [FAQItem]

        var body: some View {
            VStack(spacing: 0) {
                ForEach(questions) { item in
                    FAQRow(
                        question: item.question,
                        answer: item.answer,
                        initiallyExpanded: item.id == questions.first?.id
                    )
                    if item.id != questions.last?.id {
                        Divider().registrySeparator()
                    }
                }
            }
            .disclosureGroupStyle(.registryAccordion)
            .padding(.horizontal, theme.metrics.standardSpacing)
            .registrySurface()
        }
    }

    private struct FAQRow: View {
        let question: String
        let answer: String
        @State private var isExpanded: Bool

        init(question: String, answer: String, initiallyExpanded: Bool = false) {
            self.question = question
            self.answer = answer
            _isExpanded = State(initialValue: initiallyExpanded)
        }

        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                Text(answer)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } label: {
                Text(question)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private struct FAQItem: Identifiable {
        let id: String
        let question: String
        let answer: String
    }

    private enum Topic: String, CaseIterable, Identifiable {
        case general, billing, goals

        var id: String { rawValue }

        var title: LocalizedStringResource {
            switch self {
            case .general: "General"
            case .billing: "Billing"
            case .goals: "Goals"
            }
        }

        var questions: [FAQItem] {
            switch self {
            case .general: Faq.generalQuestions
            case .billing: Faq.billingQuestions
            case .goals: Faq.goalsQuestions
            }
        }
    }

    private nonisolated static let generalQuestions: [FAQItem] = [
        FAQItem(
            id: "security",
            question: "How secure is my financial data?",
            answer: "We use bank-level AES-256 encryption, independently audited infrastructure, and never store your credentials. All connections use read-only access tokens."
        ),
        FAQItem(
            id: "connect",
            question: "How do I connect my bank or investment accounts?",
            answer: "Open Settings, then Linked Accounts, and search for your institution. We support thousands of banks and brokerages through a secured account aggregator."
        ),
        FAQItem(
            id: "export",
            question: "Can I export my data for tax purposes?",
            answer: "Yes. Open Reports, then Tax Export, to download a CSV or PDF summary of your transactions, dividends, and gains for any tax year."
        ),
    ]

    private nonisolated static let billingQuestions: [FAQItem] = [
        FAQItem(
            id: "tiers",
            question: "What is the difference between the Basic and Pro tiers?",
            answer: "Basic includes budgeting, goal tracking, and up to three linked accounts. Pro adds unlimited accounts, dividend tracking, portfolio analysis, and priority support."
        ),
        FAQItem(
            id: "cancel",
            question: "How do I cancel my subscription?",
            answer: "Open Settings, then Billing, then Manage Plan, and choose Cancel. Your access continues until the end of the current billing period."
        ),
        FAQItem(
            id: "trial",
            question: "Do you offer a free trial?",
            answer: "Yes. Every new account starts with a fourteen-day Pro trial. No card required."
        ),
    ]

    private nonisolated static let goalsQuestions: [FAQItem] = [
        FAQItem(
            id: "custom",
            question: "How do I set up a custom financial goal?",
            answer: "Choose New Goal from the Savings Targets card. Pick a category, set a target amount and date, and we calculate the monthly contribution needed."
        ),
        FAQItem(
            id: "multiple",
            question: "Can I track multiple goals at once?",
            answer: "Yes. Pro accounts track unlimited goals. Basic accounts support up to three active goals."
        ),
        FAQItem(
            id: "calculated",
            question: "How are monthly contributions calculated?",
            answer: "We divide the remaining amount by the months until your target date, adjusted for your savings rate and any auto-transfer schedules."
        ),
    ]
}

#if DEBUG
#Preview("FAQ") {
    ScrollView { Faq().padding() }
        .registryTheme(.indigo)
}

#Preview("FAQ Dark") {
    ScrollView { Faq().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
