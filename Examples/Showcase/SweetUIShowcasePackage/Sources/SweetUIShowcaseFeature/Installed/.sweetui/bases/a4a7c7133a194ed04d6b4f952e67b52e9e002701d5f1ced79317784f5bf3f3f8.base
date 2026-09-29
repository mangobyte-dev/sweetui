import SwiftUI
import SweetUIFoundations

/// A feedback form, translated from shadcn's feedback-form: a topic picker and
/// a multi-line feedback field with a submit action. The topic is a native
/// menu `Picker` and the feedback is a `TextEditor` on the registry text-area
/// treatment; the label, the controls, and the button stay native at the call
/// site.
public struct FeedbackForm: View {
    @Environment(\.registryTheme) private var theme
    @State private var topic = ""
    @State private var feedback = "The new dashboard loads noticeably faster. Nice work."

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                FieldGroup {
                    Field("Topic") { _ in
                        Picker("Topic", selection: $topic) {
                            Text("Select a topic").tag("")
                            ForEach(topics, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Topic")
                    }

                    Field("Feedback") { _ in
                        TextEditor(text: $feedback)
                            .registryTextArea(accessibilityLabel: Text("Feedback"))
                    }
                }

                Button("Submit") {}
                    .buttonStyle(.registry)
                    .frame(maxWidth: .infinity)
            }
        } label: {
            Text("Feedback")
        }
        .groupBoxStyle(.registryCard)
    }

    private let topics = [
        "AI", "Accounts and access", "Billing", "CDN and caching", "CI/CD",
        "Dashboard", "Domains", "Frameworks", "Integrations", "Observability", "Storage",
    ]
}

#if DEBUG
#Preview("Feedback Form") {
    ScrollView { FeedbackForm().padding() }
        .registryTheme(.indigo)
}

#Preview("Feedback Form Dark") {
    ScrollView { FeedbackForm().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
