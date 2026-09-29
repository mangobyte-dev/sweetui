import Accessibility
import Foundation
import SwiftUI
import SweetUIFoundations

/// A form field composition: a visible label above caller-provided content,
/// with an optional description and an optional error message. The content
/// builder receives the invalid state, so a native control can adopt it, such
/// as a `TextField` styled with `RegistryInputStyle(isInvalid:)`. The label,
/// the control, and the messages stay native at the call site; the field owns
/// only the vertical rhythm and the error's accessibility behavior.
public struct Field<Content: View>: View {
    @Environment(\.registryTheme) private var theme

    private let label: LocalizedStringResource
    private let description: LocalizedStringResource?
    private let error: String?
    private let content: (Bool) -> Content

    /// - Parameters:
    ///   - label: The field's visible label. Give the control the same text as
    ///     its `accessibilityLabel`; a separate label view is not associated
    ///     with the control automatically.
    ///   - description: Guidance shown below the content and read as the
    ///     content's accessibility hint when no error is present.
    ///   - error: A validation message. When it is non-nil the content builder
    ///     is called with `isInvalid == true`, the message shows in the negative
    ///     color, is announced, and is read as the content's hint.
    ///   - content: The field's control. The `Bool` is the invalid state, true
    ///     when `error` is non-nil.
    public init(
        _ label: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        error: LocalizedStringResource? = nil,
        @ViewBuilder content: @escaping (Bool) -> Content
    ) {
        self.label = label
        self.description = description
        self.error = error.map { String(localized: $0) }
        self.content = content
    }

    /// The same field with a validation message computed at runtime, such as
    /// a `String?` produced by a validator. A literal or `nil` still resolves to
    /// the localized initializer above; this one is chosen only when the
    /// argument is a `String`.
    @_disfavoredOverload
    public init(
        _ label: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        error: String?,
        @ViewBuilder content: @escaping (Bool) -> Content
    ) {
        self.label = label
        self.description = description
        self.error = error
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            Text(label)
                .font(.subheadline.weight(.medium))

            content(error != nil)
                .accessibilityHint(hint ?? Text(verbatim: ""), isEnabled: hint != nil)

            if let description, error == nil {
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let error {
                Text(verbatim: error)
                    .font(.footnote)
                    .foregroundStyle(theme.negative)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: error) { _, message in announce(message) }
        .registryItem("field")
    }

    /// The error takes the hint when present, otherwise the description; a
    /// focused control then re-reads the most urgent message.
    private var hint: Text? {
        if let error {
            return Text(verbatim: error)
        }
        if let description {
            return Text(description)
        }
        return nil
    }

    private func announce(_ message: String?) {
        guard let message else { return }
        AccessibilityNotification.Announcement(message).post()
    }
}

/// A vertical stack of ``Field`` values on the shared section rhythm. Use it
/// when a card presents several fields together; a single field needs no group.
public struct FieldGroup<Content: View>: View {
    @Environment(\.registryTheme) private var theme
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .registryItem("field")
    }
}

private struct FieldPreview: View {
    var showErrors = false

    @State private var email = ""
    @State private var role = "member"

    var body: some View {
        FieldGroup {
            Field(
                "Full name",
                description: "As it appears on your card."
            ) { _ in
                TextField("Full name", text: .constant("Maya Khalid"))
                    .textFieldStyle(.registryInput)
                    .accessibilityLabel("Full name")
            }

            Field(
                "Email",
                error: showErrors ? "Enter a valid email address." : nil
            ) { isInvalid in
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
        .padding()
    }
}

#Preview("Field") {
    FieldPreview().tint(.indigo)
}

#Preview("Field Error") {
    FieldPreview(showErrors: true).tint(.indigo)
}

#Preview("Field Dark") {
    FieldPreview(showErrors: true).tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Field Right to Left") {
    FieldPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Field Accessibility Size") {
    FieldPreview(showErrors: true).tint(.indigo).dynamicTypeSize(.accessibility3)
}
