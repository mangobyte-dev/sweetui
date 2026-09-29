import Accessibility
import Foundation
import SwiftUI
import SweetUIFoundations

/// A source-owned sign-in block composing the registry input, button, and card
/// treatments around native `TextField`, `SecureField`, and `Button`.
/// The caller owns credentials, validation results, and submission state; the
/// block owns only transient keyboard focus. No networking, validation logic,
/// or credential storage lives inside. The block does not own a `ScrollView`,
/// navigation container, or maximum width.
public struct AuthForm: View {

    /// The kind of identity credential the form collects. Drives only the
    /// keyboard type; autofill content types are fixed (`.username` / `.password`).
    public enum IdentityKind: Sendable {
        case email
        case username
    }

    private let title: LocalizedStringResource
    private let identityTitle: LocalizedStringResource
    @Binding private var identity: String
    private let identityKind: IdentityKind
    private let identityError: LocalizedStringResource?
    private let passwordTitle: LocalizedStringResource
    @Binding private var password: String
    private let passwordError: LocalizedStringResource?
    private let formError: LocalizedStringResource?
    private let submitTitle: LocalizedStringResource
    private let isSubmitting: Bool
    private let secondaryActionTitle: LocalizedStringResource?
    private let onSecondaryAction: (() -> Void)?
    private let onSubmit: () -> Void

    @Environment(\.registryTheme) private var theme
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case identity
        case password
    }

    /// Parameters mirror the block grammar: unlabeled title, labeled prepared
    /// values with defaults, trailing action closure.
    /// `secondaryActionTitle` and `onSecondaryAction` must be supplied
    /// together; the row renders only when both are non-nil.
    public init(
        _ title: LocalizedStringResource,
        identityTitle: LocalizedStringResource = "Email",
        identity: Binding<String>,
        identityKind: IdentityKind = .email,
        identityError: LocalizedStringResource? = nil,
        passwordTitle: LocalizedStringResource = "Password",
        password: Binding<String>,
        passwordError: LocalizedStringResource? = nil,
        formError: LocalizedStringResource? = nil,
        submitTitle: LocalizedStringResource = "Sign in",
        isSubmitting: Bool = false,
        secondaryActionTitle: LocalizedStringResource? = nil,
        onSecondaryAction: (() -> Void)? = nil,
        onSubmit: @escaping () -> Void
    ) {
        self.title = title
        self.identityTitle = identityTitle
        self._identity = identity
        self.identityKind = identityKind
        self.identityError = identityError
        self.passwordTitle = passwordTitle
        self._password = password
        self.passwordError = passwordError
        self.formError = formError
        self.submitTitle = submitTitle
        self.isSubmitting = isSubmitting
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
                    TextField(text: $identity, prompt: Text(identityTitle)) {
                        Text(identityTitle)
                    }
                    .accessibilityLabel(Text(identityTitle))
                    .textFieldStyle(RegistryInputStyle(isInvalid: identityError != nil))
                    .textContentType(.username)
                    .keyboardType(identityKind == .email ? .emailAddress : .asciiCapable)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focusedField, equals: .identity)
                    .onSubmit { focusedField = .password }
                    .accessibilityHint(identityError.map { Text($0) } ?? Text(verbatim: ""), isEnabled: identityError != nil)

                    fieldMessage(identityError)
                }

                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                    SecureField(text: $password, prompt: Text(passwordTitle)) {
                        Text(passwordTitle)
                    }
                    .accessibilityLabel(Text(passwordTitle))
                    .textFieldStyle(RegistryInputStyle(isInvalid: passwordError != nil))
                    .textContentType(.password)
                    .submitLabel(.go)
                    .focused($focusedField, equals: .password)
                    .onSubmit {
                        if !isSubmitting {
                            onSubmit()
                        }
                    }
                    .accessibilityHint(passwordError.map { Text($0) } ?? Text(verbatim: ""), isEnabled: passwordError != nil)

                    fieldMessage(passwordError)
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
        .onChange(of: identityError) { _, message in announce(message) }
        .onChange(of: passwordError) { _, message in announce(message) }
        .onChange(of: formError) { _, message in announce(message) }
        .registryItem("auth-form")
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
private struct AuthFormPreview: View {
    var showErrors = false
    var isSubmitting = false

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            AuthForm(
                "Welcome back",
                identity: $email,
                identityError: showErrors ? "Enter a valid email address" : nil,
                password: $password,
                passwordError: showErrors ? "Enter your password" : nil,
                formError: showErrors ? "We could not sign you in. Try again." : nil,
                isSubmitting: isSubmitting,
                secondaryActionTitle: "Forgot password?",
                onSecondaryAction: {},
                onSubmit: {}
            )
            .padding()
        }
    }
}

#Preview("Auth Form") {
    AuthFormPreview()
}

#Preview("Auth Form Error") {
    AuthFormPreview(showErrors: true)
}

#Preview("Auth Form Submitting") {
    AuthFormPreview(isSubmitting: true)
}

#Preview("Auth Form Dark") {
    AuthFormPreview()
        .preferredColorScheme(.dark)
}

#Preview("Auth Form Right to Left") {
    AuthFormPreview()
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Auth Form Accessibility Size") {
    AuthFormPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
