import Accessibility
import Foundation
import SwiftUI
import SweetUIFoundations

// MARK: - Prepared values

/// One selectable answer in a single-choice or multiple-choice step.
public struct QuestionnaireOption: Identifiable, Sendable {
    public let id: String
    public let title: LocalizedStringResource

    public init(id: String, title: LocalizedStringResource) {
        self.id = id
        self.title = title
    }
}

/// The control a step presents. Single choice is a native inline `Picker`,
/// multiple choice is a column of native checkbox `Toggle`s, and freeform is a
/// native `TextEditor` prompted for what to write.
public enum QuestionnaireStepKind {
    case singleChoice([QuestionnaireOption])
    case multipleChoice([QuestionnaireOption])
    case freeform(prompt: LocalizedStringResource)
}

/// One step of the questionnaire. A skippable step lets the caller advance
/// without an answer.
public struct QuestionnaireStep: Identifiable {
    public let id: String
    public let title: LocalizedStringResource
    public let description: LocalizedStringResource?
    public let kind: QuestionnaireStepKind
    public let isSkippable: Bool

    public init(
        id: String,
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        kind: QuestionnaireStepKind,
        isSkippable: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.kind = kind
        self.isSkippable = isSkippable
    }
}

/// The caller-owned answer for one step, keyed by the step's id in the block's
/// `answers` binding.
public enum QuestionnaireAnswer: Equatable, Sendable {
    case single(String)
    case multiple(Set<String>)
    case freeform(String)
}

// MARK: - Block

/// A source-owned multi-step questionnaire block composing the registry field,
/// checkbox, textarea, progress, button, and card treatments around native
/// `Picker`, `Toggle`, `TextEditor`, and `Button` controls.
///
/// The caller owns the current step index and every answer through bindings;
/// the block records answers as the controls change and never validates,
/// stores, or transports them. The block owns no state of its own. It does not
/// own a `ScrollView`, navigation container, or maximum width.
public struct Questionnaire: View {
    private let title: LocalizedStringResource
    private let steps: [QuestionnaireStep]
    @Binding private var currentStep: Int
    @Binding private var answers: [String: QuestionnaireAnswer]
    private let finishTitle: LocalizedStringResource
    private let onFinish: () -> Void

    @Environment(\.registryTheme) private var theme

    /// Parameters mirror the block grammar: unlabeled title, labeled prepared
    /// values and bindings with defaults, trailing action closure.
    /// - Parameters:
    ///   - title: The questionnaire's heading, shown with the header trait.
    ///   - steps: The ordered steps. Each carries its own control kind.
    ///   - currentStep: The caller-owned index of the visible step.
    ///   - answers: The caller-owned answers, keyed by step id.
    ///   - finishTitle: The primary button's title on the last step.
    ///   - onFinish: Called when the primary button is tapped on the last step.
    public init(
        _ title: LocalizedStringResource,
        steps: [QuestionnaireStep],
        currentStep: Binding<Int>,
        answers: Binding<[String: QuestionnaireAnswer]>,
        finishTitle: LocalizedStringResource = "Finish",
        onFinish: @escaping () -> Void
    ) {
        self.title = title
        self.steps = steps
        self._currentStep = currentStep
        self._answers = answers
        self.finishTitle = finishTitle
        self.onFinish = onFinish
    }

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                if let index = resolvedIndex {
                    let step = steps[index]

                    progressLine(index: index)
                    stepField(step)
                    buttonRow(step: step, index: index)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text(title)
                .accessibilityAddTraits(.isHeader)
        }
        .groupBoxStyle(.registryCard)
        .onChange(of: currentStep) { _, newValue in announceStep(at: newValue) }
        .registryItem("questionnaire")
    }

    // MARK: Sections

    @ViewBuilder
    private func progressLine(index: Int) -> some View {
        let fraction = Double(index + 1) / Double(steps.count)

        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            Text("Step \(index + 1) of \(steps.count)")
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)

            ProgressView(value: fraction)
                .progressViewStyle(.registryLinear)
                .accessibilityLabel(Text("Progress"))
        }
    }

    @ViewBuilder
    private func stepField(_ step: QuestionnaireStep) -> some View {
        Field(step.title, description: step.description) { _ in
            stepControl(step)
        }
    }

    @ViewBuilder
    private func stepControl(_ step: QuestionnaireStep) -> some View {
        switch step.kind {
        case .singleChoice(let options):
            Picker(selection: singleSelection(for: step.id)) {
                ForEach(options) { option in
                    Text(option.title).tag(option.id)
                }
            } label: {
                Text(step.title)
            }
            .pickerStyle(.inline)
            .labelsHidden()

        case .multipleChoice(let options):
            VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                ForEach(options) { option in
                    Toggle(isOn: multipleSelection(stepID: step.id, optionID: option.id)) {
                        Text(option.title)
                    }
                    .accessibilityLabel(Text(option.title))
                }
            }
            .toggleStyle(.registryCheckbox)

        case .freeform(let prompt):
            TextEditor(text: freeformText(for: step.id))
                .registryTextArea(accessibilityLabel: Text(prompt), minimumHeight: 120)
        }
    }

    @ViewBuilder
    private func buttonRow(step: QuestionnaireStep, index: Int) -> some View {
        let isFirst = index <= 0
        let isLast = index >= steps.count - 1

        ViewThatFits(in: .horizontal) {
            HStack(spacing: theme.metrics.compactSpacing) {
                buttons(step: step, isFirst: isFirst, isLast: isLast)
            }
            VStack(spacing: theme.metrics.compactSpacing) {
                buttons(step: step, isFirst: isFirst, isLast: isLast)
            }
        }
    }

    @ViewBuilder
    private func buttons(step: QuestionnaireStep, isFirst: Bool, isLast: Bool) -> some View {
        if !isFirst {
            Button {
                goBack()
            } label: {
                Text("Back")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.registryOutline)
            .controlSize(.large)
            .accessibilityLabel(Text("Back"))
        }

        if step.isSkippable {
            Button {
                advance(isLast: isLast)
            } label: {
                Text("Skip")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.registryLink)
            .controlSize(.large)
            .accessibilityLabel(Text("Skip"))
        }

        Button {
            advance(isLast: isLast)
        } label: {
            Text(isLast ? finishTitle : "Next")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.registry)
        .controlSize(.large)
        .disabled(!step.isSkippable && !hasAnswer(for: step))
        .accessibilityLabel(Text(isLast ? finishTitle : "Next"))
    }

    // MARK: Navigation

    private var resolvedIndex: Int? {
        steps.indices.contains(currentStep) ? currentStep : nil
    }

    /// Advances to the next step, or finishes when already on the last step.
    /// Both Next and Skip route here; neither records an answer, so a skipped
    /// step simply leaves its key absent from `answers`.
    private func advance(isLast: Bool) {
        if isLast {
            onFinish()
        } else {
            currentStep += 1
        }
    }

    private func goBack() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }

    private func announceStep(at index: Int) {
        guard steps.indices.contains(index) else { return }
        AccessibilityNotification.Announcement(String(localized: steps[index].title)).post()
    }

    private func hasAnswer(for step: QuestionnaireStep) -> Bool {
        switch answers[step.id] {
        case .single(let id):
            return !id.isEmpty
        case .multiple(let ids):
            return !ids.isEmpty
        case .freeform(let text):
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case nil:
            return false
        }
    }

    // MARK: Derived bindings

    /// These bindings capture only the caller's `answers` binding and the
    /// relevant ids, all `Sendable`, so the `@Sendable` `Binding` closures never
    /// capture the non-`Sendable` view or step.
    private func singleSelection(for stepID: String) -> Binding<String> {
        let answers = $answers
        return Binding(
            get: {
                if case .single(let id) = answers.wrappedValue[stepID] { return id }
                return ""
            },
            set: { answers.wrappedValue[stepID] = .single($0) }
        )
    }

    private func multipleSelection(stepID: String, optionID: String) -> Binding<Bool> {
        let answers = $answers
        return Binding(
            get: {
                if case .multiple(let ids) = answers.wrappedValue[stepID] {
                    return ids.contains(optionID)
                }
                return false
            },
            set: { isOn in
                var ids: Set<String>
                if case .multiple(let existing) = answers.wrappedValue[stepID] {
                    ids = existing
                } else {
                    ids = []
                }
                if isOn {
                    ids.insert(optionID)
                } else {
                    ids.remove(optionID)
                }
                answers.wrappedValue[stepID] = .multiple(ids)
            }
        )
    }

    private func freeformText(for stepID: String) -> Binding<String> {
        let answers = $answers
        return Binding(
            get: {
                if case .freeform(let text) = answers.wrappedValue[stepID] { return text }
                return ""
            },
            set: { answers.wrappedValue[stepID] = .freeform($0) }
        )
    }
}

#if DEBUG
private struct QuestionnairePreview: View {
    @State private var currentStep: Int
    @State private var answers: [String: QuestionnaireAnswer]

    init(startStep: Int = 0, answers: [String: QuestionnaireAnswer] = [:]) {
        self._currentStep = State(initialValue: startStep)
        self._answers = State(initialValue: answers)
    }

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
        ScrollView {
            Questionnaire(
                "Set up your profile",
                steps: steps,
                currentStep: $currentStep,
                answers: $answers,
                onFinish: {}
            )
            .padding()
        }
    }
}

#Preview("Questionnaire") {
    QuestionnairePreview().tint(.indigo)
}

#Preview("Questionnaire Multiple Choice") {
    QuestionnairePreview(startStep: 1).tint(.indigo)
}

#Preview("Questionnaire Freeform") {
    QuestionnairePreview(startStep: 2).tint(.indigo)
}

#Preview("Questionnaire Dark") {
    QuestionnairePreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Questionnaire Right to Left") {
    QuestionnairePreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Questionnaire Accessibility Size") {
    QuestionnairePreview(startStep: 1).tint(.indigo).dynamicTypeSize(.accessibility3)
}
#endif
