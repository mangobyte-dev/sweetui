import Accessibility
import Foundation
import SwiftUI
import SweetUIFoundations

/// A source-owned sign-up block composing the registry input, button, card, and
/// checkbox treatments around native `TextField`, `SecureField`, `Toggle`, and
/// `Button`. The caller owns the field values, validation results, terms
/// acceptance, and submission state; the block owns only transient keyboard
/// focus. No networking, validation logic, or credential storage lives inside.
/// The block does not own a `ScrollView`, navigation container, or maximum width.
public struct SignUpForm: View {

    private let title: LocalizedStringResource
    private let nameTitle: LocalizedStringResource
    @Binding private var name: String
    private let nameError: LocalizedStringResource?
    private let emailTitle: LocalizedStringResource
    @Binding private var email: String
    private let emailError: LocalizedStringResource?
    private let passwordTitle: LocalizedStringResource
    @Binding private var password: String
    private let passwordError: LocalizedStringResource?
    private let confirmationTitle: LocalizedStringResource
    @Binding private var confirmation: String
    private let confirmationError: LocalizedStringResource?
    private let termsTitle: LocalizedStringResource
    @Binding private var acceptsTerms: Bool
    private let termsError: LocalizedStringResource?
    private let formError: LocalizedStringResource?
    private let submitTitle: LocalizedStringResource
    private let isSubmitting: Bool
    private let isSubmitEnabled: Bool
    private let secondaryActionTitle: LocalizedStringResource?
    private let onSecondaryAction: (() -> Void)?
    private let onSubmit: () -> Void

    @Environment(\.registryTheme) private var theme
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name
        case email
        case password
        case confirmation
    }

    /// Parameters mirror the block grammar: unlabeled title, labeled prepared
    /// values with defaults, bindings, error strings, submission state, trailing
    /// action closure. `secondaryActionTitle` and `onSecondaryAction` must be
    /// supplied together; the row renders only when both are non-nil.
    public init(
        _ title: LocalizedStringResource,
        nameTitle: LocalizedStringResource = "Full name",
        name: Binding<String>,
        nameError: LocalizedStringResource? = nil,
        emailTitle: LocalizedStringResource = "Email",
        email: Binding<String>,
        emailError: LocalizedStringResource? = nil,
        passwordTitle: LocalizedStringResource = "Password",
        password: Binding<String>,
        passwordError: LocalizedStringResource? = nil,
        confirmationTitle: LocalizedStringResource = "Confirm password",
        confirmation: Binding<String>,
        confirmationError: LocalizedStringResource? = nil,
        termsTitle: LocalizedStringResource = "I agree to the terms of service",
        acceptsTerms: Binding<Bool>,
        termsError: LocalizedStringResource? = nil,
        formError: LocalizedStringResource? = nil,
        submitTitle: LocalizedStringResource = "Create account",
        isSubmitting: Bool = false,
        isSubmitEnabled: Bool = true,
        secondaryActionTitle: LocalizedStringResource? = nil,
        onSecondaryAction: (() -> Void)? = nil,
        onSubmit: @escaping () -> Void
    ) {
        self.title = title
        self.nameTitle = nameTitle
        self._name = name
        self.nameError = nameError
        self.emailTitle = emailTitle
        self._email = email
        self.emailError = emailError
        self.passwordTitle = passwordTitle
        self._password = password
        self.passwordError = passwordError
        self.confirmationTitle = confirmationTitle
        self._confirmation = confirmation
        self.confirmationError = confirmationError
        self.termsTitle = termsTitle
        self._acceptsTerms = acceptsTerms
        self.termsError = termsError
        self.formError = formError
        self.submitTitle = submitTitle
        self.isSubmitting = isSubmitting
        self.isSubmitEnabled = isSubmitEnabled
        self.secondaryActionTitle = secondaryActionTitle
        self.onSecondaryAction = onSecondaryAction
        self.onSubmit = onSubmit
    }

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                    // The title is placeholder text to VoiceOver; the explicit
                    // label keeps the field named once it holds text.
                    TextField(text: $name, prompt: Text(nameTitle)) {
                        Text(nameTitle)
                    }
                    .accessibilityLabel(Text(nameTitle))
                    .textFieldStyle(RegistryInputStyle(isInvalid: nameError != nil))
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .name)
                    .onSubmit { focusedField = .email }
                    .accessibilityHint(nameError.map { Text($0) } ?? Text(verbatim: ""), isEnabled: nameError != nil)

                    fieldMessage(nameError)
                }

                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                    TextField(text: $email, prompt: Text(emailTitle)) {
                        Text(emailTitle)
                    }
                    .accessibilityLabel(Text(emailTitle))
                    .textFieldStyle(RegistryInputStyle(isInvalid: emailError != nil))
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focusedField, equals: .email)
                    .onSubmit { focusedField = .password }
                    .accessibilityHint(emailError.map { Text($0) } ?? Text(verbatim: ""), isEnabled: emailError != nil)

                    fieldMessage(emailError)
                }

                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                    SecureField(text: $password, prompt: Text(passwordTitle)) {
                        Text(passwordTitle)
                    }
                    .accessibilityLabel(Text(passwordTitle))
                    .textFieldStyle(RegistryInputStyle(isInvalid: passwordError != nil))
                    .textContentType(.newPassword)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .password)
                    .onSubmit { focusedField = .confirmation }
                    .accessibilityHint(passwordError.map { Text($0) } ?? Text(verbatim: ""), isEnabled: passwordError != nil)

                    fieldMessage(passwordError)
                }

                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                    SecureField(text: $confirmation, prompt: Text(confirmationTitle)) {
                        Text(confirmationTitle)
                    }
                    .accessibilityLabel(Text(confirmationTitle))
                    .textFieldStyle(RegistryInputStyle(isInvalid: confirmationError != nil))
                    .textContentType(.newPassword)
                    .submitLabel(.go)
                    .focused($focusedField, equals: .confirmation)
                    .onSubmit {
                        if !isSubmitting, isSubmitEnabled {
                            onSubmit()
                        }
                    }
                    .accessibilityHint(confirmationError.map { Text($0) } ?? Text(verbatim: ""), isEnabled: confirmationError != nil)

                    fieldMessage(confirmationError)
                }

                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                    Toggle(termsTitle, isOn: $acceptsTerms)
                        .toggleStyle(.registryCheckbox)

                    fieldMessage(termsError)
                }

                fieldMessage(formError)

                Button {
                    onSubmit()
                } label: {
                    ZStack {
                        Text(submitTitle)
                            .opacity(isSubmitting ? 0 : 1)
                        if isSubmitting {
                            // Explicit tint: the spinner sits on the accent
                            // fill, so it uses the same foreground as the
                            // primary button label.
                            ProgressView()
                                .tint(theme.onAccent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.registry)
                .controlSize(.large)
                .disabled(!isSubmitEnabled)
                .accessibilityLabel(Text(submitTitle))

                if let secondaryActionTitle, let onSecondaryAction {
                    Button(action: onSecondaryAction) {
                        Text(secondaryActionTitle)
                    }
                    .buttonStyle(.registryLink)
                }
            }
            .disabled(isSubmitting)
        } label: {
            Text(title)
                .accessibilityAddTraits(.isHeader)
        }
        .groupBoxStyle(.registryCard)
        .onChange(of: nameError) { _, message in announce(message) }
        .onChange(of: emailError) { _, message in announce(message) }
        .onChange(of: passwordError) { _, message in announce(message) }
        .onChange(of: confirmationError) { _, message in announce(message) }
        .onChange(of: termsError) { _, message in announce(message) }
        .onChange(of: formError) { _, message in announce(message) }
        .registryItem("signup-form")
    }

    @ViewBuilder
    private func fieldMessage(_ message: LocalizedStringResource?) -> some View {
        if let message {
            Text(message)
                .font(.footnote)
                .foregroundStyle(theme.negative)
        }
    }

    private func announce(_ message: LocalizedStringResource?) {
        guard let message else { return }
        AccessibilityNotification.Announcement(String(localized: message)).post()
    }
}

#if DEBUG
private struct SignUpFormPreview: View {
    var showErrors = false
    var isSubmitting = false

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var acceptsTerms = false

    var body: some View {
        ScrollView {
            SignUpForm(
                "Create your account",
                name: $name,
                nameError: showErrors ? "Enter your name" : nil,
                email: $email,
                emailError: showErrors ? "Enter a valid email address" : nil,
                password: $password,
                passwordError: showErrors ? "Use at least 8 characters" : nil,
                confirmation: $confirmation,
                confirmationError: showErrors ? "Passwords do not match" : nil,
                acceptsTerms: $acceptsTerms,
                termsError: showErrors ? "Accept the terms to continue" : nil,
                formError: showErrors ? "We could not create your account. Try again." : nil,
                isSubmitting: isSubmitting,
                secondaryActionTitle: "Already have an account?",
                onSecondaryAction: {},
                onSubmit: {}
            )
            .padding()
        }
    }
}

#Preview("Sign Up Form") {
    SignUpFormPreview()
}

#Preview("Sign Up Form Errors") {
    SignUpFormPreview(showErrors: true)
}

#Preview("Sign Up Form Dark") {
    SignUpFormPreview()
        .preferredColorScheme(.dark)
}

#Preview("Sign Up Form Right to Left") {
    SignUpFormPreview()
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Sign Up Form Accessibility Size") {
    SignUpFormPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
