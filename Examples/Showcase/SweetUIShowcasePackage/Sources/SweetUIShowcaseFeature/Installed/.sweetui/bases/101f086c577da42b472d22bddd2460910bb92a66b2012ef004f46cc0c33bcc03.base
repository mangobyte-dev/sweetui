import Accessibility
import SwiftUI
import SweetUIFoundations

/// A rule a ``ValidatedInput`` checks its text against. Rules run in order and
/// the first failure is the message shown; `required` is checked only when
/// the field loses focus, so an empty field is not shouted at while typing.
public enum InputValidation: Sendable {
    /// The field must not be empty when it loses focus.
    case required
    /// A plain email address such as `name@example.com`.
    case email
    /// Ten digits, no separators.
    case phone
    /// A caller-owned check over the whole text.
    case custom(@Sendable (String) -> ValidationResult)

    /// A password rule with the requirements switched on by default.
    public static func password(
        minLength: Int = 8,
        requiresUppercase: Bool = true,
        requiresNumber: Bool = true,
        requiresSpecial: Bool = true
    ) -> Self {
        .custom { text in
            guard text.count >= minLength else {
                return .invalid("Must be at least \(minLength) characters")
            }
            if requiresUppercase, !text.contains(where: \.isUppercase) {
                return .invalid("Must contain an uppercase letter")
            }
            if requiresNumber, !text.contains(where: \.isNumber) {
                return .invalid("Must contain a number")
            }
            if requiresSpecial, !text.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) {
                return .invalid("Must contain a special character")
            }
            return .valid
        }
    }

    /// The text must equal `other`, for a confirmation field.
    public static func matching(_ other: String, message: LocalizedStringResource = "Fields don't match") -> Self {
        .custom { text in text == other ? .valid : .invalid(message) }
    }

    /// The text must parse as an integer inside the closed range.
    public static func numberRange(min: Int, max: Int, message: LocalizedStringResource? = nil) -> Self {
        .custom { text in
            guard let number = Int(text) else { return .invalid("Please enter a valid number") }
            guard (min...max).contains(number) else {
                return .invalid(message ?? "Value must be between \(min) and \(max)")
            }
            return .valid
        }
    }

    /// E.164: a plus sign, then 2 to 15 digits.
    public static var internationalPhone: Self {
        .pattern(#"\+[1-9]\d{1,14}"#, message: "Enter an international number such as +1234567890")
    }

    /// The whole text must match the regular expression.
    public static func pattern(_ pattern: String, message: LocalizedStringResource) -> Self {
        .custom { text in
            guard let regex = try? Regex(pattern), text.wholeMatch(of: regex) != nil else {
                return .invalid(message)
            }
            return .valid
        }
    }
}

/// The outcome of one ``InputValidation``.
public enum ValidationResult: Sendable {
    case valid
    case invalid(LocalizedStringResource)
}

/// What a ``ValidatedInput`` currently shows: the field's validity, given to
/// the caller through the `validity` binding so a form can gate its submit.
public enum InputValidity: Equatable, Sendable {
    /// Nothing typed yet, or the field has not been touched.
    case empty
    case valid
    /// The first failing rule's message.
    case invalid(String)

    public var isValid: Bool { self == .valid }
}

/// A text field with a floating label, a rounded border that follows focus
/// and validity, and rules checked while typing and again on blur. The label
/// rises inside the field, and a field with rules reserves its message
/// line, so neither focus nor an error moves the views around it. The
/// caller owns the text; the field owns focus and its validation state.
/// Apply `keyboardType`, `textContentType`, or `textInputAutocapitalization`
/// outside; they reach the inner field through the environment.
public struct ValidatedInput: View {
    @Environment(\.registryTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool
    @State private var state: State = .idle

    private let label: LocalizedStringResource
    @Binding private var text: String
    private let validations: [InputValidation]
    private let isSecure: Bool
    private let validity: Binding<InputValidity>?

    /// - Parameters:
    ///   - label: The floating label, also the field's accessibility label.
    ///   - text: The caller-owned text.
    ///   - validations: Rules checked in order; the first failure shows.
    ///   - isSecure: Uses a `SecureField` for passwords.
    ///   - validity: Receives every validity change, for submit gating.
    public init(
        _ label: LocalizedStringResource,
        text: Binding<String>,
        validations: [InputValidation] = [],
        isSecure: Bool = false,
        validity: Binding<InputValidity>? = nil
    ) {
        self.label = label
        self._text = text
        self.validations = validations
        self.isSecure = isSecure
        self.validity = validity
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            field
            // A field with rules always reserves its message line, so an error
            // never moves the views below it.
            if !validations.isEmpty {
                ZStack(alignment: .leading) {
                    Text(verbatim: " ").font(.footnote).hidden()
                    if case .invalid(let message) = state.validity {
                        Text(verbatim: message)
                            .font(.footnote)
                            .foregroundStyle(theme.negative)
                    }
                }
                .padding(.leading, theme.metrics.controlHorizontalPadding)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(isEnabled ? 1 : theme.disabledOpacity)
        .animation(reduceMotion ? nil : .spring(duration: 0.2), value: state)
        .animation(reduceMotion ? nil : .spring(duration: 0.2), value: isRaised)
        .onAppear { if !text.isEmpty { update() } }
        .onChange(of: text) { _, _ in update() }
        .onChange(of: isFocused) { _, _ in update() }
        .onChange(of: state.validity) { _, validity in
            self.validity?.wrappedValue = validity
            if case .invalid(let message) = validity {
                AccessibilityNotification.Announcement(message).post()
            }
        }
        .registryItem("validated-input")
    }

    @ViewBuilder
    private var field: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        // The label line above the text is always reserved by a hidden copy of
        // the label, so the field keeps one height; the label rises into that
        // line inside the field and never crosses the border.
        ZStack(alignment: isRaised ? .topLeading : .leading) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.footnote).hidden()
                Group {
                    if isSecure {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .focused($isFocused)
                .accessibilityLabel(Text(label))
                .accessibilityHint(hint ?? Text(verbatim: ""), isEnabled: hint != nil)
            }
            Text(label)
                .font(isRaised ? .footnote : .body)
                .foregroundStyle(labelStyle)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, theme.metrics.controlHorizontalPadding)
        .padding(.vertical, 8)
        .frame(minHeight: RegistryMetrics.minimumHitSize)
        .background(theme.surface, in: shape)
        .overlay {
            shape.stroke(
                tint,
                lineWidth: isFocused || state.hasError
                    ? theme.metrics.emphasizedBorderWidth
                    : theme.metrics.borderWidth
            )
        }
        // The text row covers only the lower half; the whole field focuses.
        .contentShape(shape)
        .onTapGesture { isFocused = true }
    }

    private var isRaised: Bool { isFocused || !text.isEmpty }

    private var hint: Text? {
        if case .invalid(let message) = state.validity { return Text(verbatim: message) }
        return nil
    }

    private var tint: AnyShapeStyle {
        if state.hasError { return AnyShapeStyle(theme.negative) }
        if isFocused || state.validity == .valid { return AnyShapeStyle(TintShapeStyle()) }
        return AnyShapeStyle(theme.border)
    }

    private var labelStyle: AnyShapeStyle {
        if state.hasError { return AnyShapeStyle(theme.negative) }
        if isFocused { return AnyShapeStyle(TintShapeStyle()) }
        return AnyShapeStyle(.secondary)
    }

    private func update() {
        state = isFocused ? .focused(validate(onBlur: false)) : .inactive(validate(onBlur: true))
        if !isFocused, text.isEmpty, !validations.contains(where: \.isRequired) {
            state = .idle
        }
    }

    /// While typing, `required` is skipped; on blur an empty required field fails.
    private func validate(onBlur: Bool) -> InputValidity {
        if text.isEmpty {
            return onBlur && validations.contains(where: \.isRequired)
                ? .invalid(String(localized: "This field is required"))
                : .empty
        }
        for validation in validations {
            switch validation {
            case .required:
                continue
            case .email:
                if text.wholeMatch(of: /[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}/) == nil {
                    return .invalid(String(localized: "Enter a valid email address"))
                }
            case .phone:
                if text.wholeMatch(of: /\d{10}/) == nil {
                    return .invalid(String(localized: "Enter a 10-digit phone number"))
                }
            case .custom(let check):
                if case .invalid(let message) = check(text) {
                    return .invalid(String(localized: message))
                }
            }
        }
        return .valid
    }

    private enum State: Equatable {
        case idle
        case focused(InputValidity)
        case inactive(InputValidity)

        var validity: InputValidity {
            switch self {
            case .idle: .empty
            case .focused(let validity), .inactive(let validity): validity
            }
        }

        var hasError: Bool {
            if case .invalid = validity { return true }
            return false
        }
    }
}

private extension InputValidation {
    var isRequired: Bool {
        if case .required = self { return true }
        return false
    }
}

private struct ValidatedInputPreview: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var age = ""
    @State private var phone = "+96599123456"
    @State private var emailValidity: InputValidity = .empty

    var body: some View {
        VStack(spacing: 24) {
            ValidatedInput("Email", text: $email, validations: [.required, .email], validity: $emailValidity)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
            ValidatedInput(
                "Password", text: $password, validations: [.required, .password()], isSecure: true)
            ValidatedInput(
                "Confirm password", text: $confirmation,
                validations: [.required, .matching(password)], isSecure: true)
            ValidatedInput("Age", text: $age, validations: [.required, .numberRange(min: 13, max: 120)])
                .keyboardType(.numberPad)
            ValidatedInput("Phone", text: $phone, validations: [.required, .internationalPhone])
                .keyboardType(.phonePad)
            ValidatedInput("Disabled", text: .constant("Unavailable"))
                .disabled(true)
        }
        .padding()
    }
}

#Preview("Validated Input") {
    ValidatedInputPreview().tint(.indigo)
}

#Preview("Validated Input Dark") {
    ValidatedInputPreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Validated Input Right to Left") {
    ValidatedInputPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Validated Input Accessibility Size") {
    ValidatedInputPreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
