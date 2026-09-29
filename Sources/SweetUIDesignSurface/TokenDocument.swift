#if canImport(UIKit)
import Foundation
import Sharing
import SwiftUI

/// A host's own design tokens as the surface tunes them: a Codable value the
/// app declares pages of knobs for. The surface keeps it in a file of its
/// own, renders its pages in the panel, and hands every change back live
/// through ``TokenDocument/apply()``, so the app's views follow a slider with
/// no bridge code beyond the conformance. seeFood's `ThemeTokens` is the first
/// host document (Stage 9, D3); the registry's own `ThemeTuning` keeps its
/// bespoke panel and is not one.
public protocol TokenDocument: Codable, Equatable, Sendable {
    /// The shipped values, and what Reset returns to.
    static var shipped: Self { get }
    /// The file the surface keeps the tuned document in, inside Documents.
    static var fileName: String { get }
    /// The pages of knobs the panel shows, in order.
    static var pages: [TokenPage<Self>] { get }
    /// Called on the main actor after every change with the new value, so the
    /// app can push it into whatever its views read.
    @MainActor func apply()
}

/// One page of the panel for a host document: a title and its knobs.
public struct TokenPage<Document: TokenDocument>: Identifiable, Sendable {
    public let title: String
    public let knobs: [TokenKnob<Document>]
    public var id: String { title }

    public init(_ title: String, knobs: [TokenKnob<Document>]) {
        self.title = title
        self.knobs = knobs
    }
}

/// One control on a page: a numeric slider, a choice among words, or a color.
public struct TokenKnob<Document: TokenDocument>: Identifiable, Sendable {
    /// A numeric knob reads and writes through closures, so a document can
    /// keep its numbers as `Double` or `CGFloat`.
    public struct Number: Sendable {
        public let get: @Sendable (Document) -> Double
        public let set: @Sendable (inout Document, Double) -> Void
        public let range: ClosedRange<Double>
        public let step: Double
    }

    public enum Kind: Sendable {
        case number(Number)
        case choice(WritableKeyPath<Document, String> & Sendable, options: [String])
        case color(WritableKeyPath<Document, TokenColor> & Sendable)
    }

    public let title: String
    public let kind: Kind
    public var id: String { title }

    public static func number(
        _ title: String, _ keyPath: WritableKeyPath<Document, Double> & Sendable,
        in range: ClosedRange<Double>, step: Double = 1
    ) -> TokenKnob {
        TokenKnob(title: title, kind: .number(Number(
            get: { $0[keyPath: keyPath] }, set: { $0[keyPath: keyPath] = $1 }, range: range, step: step)))
    }

    public static func number(
        _ title: String, _ keyPath: WritableKeyPath<Document, CGFloat> & Sendable,
        in range: ClosedRange<Double>, step: Double = 1
    ) -> TokenKnob {
        TokenKnob(title: title, kind: .number(Number(
            get: { Double($0[keyPath: keyPath]) }, set: { $0[keyPath: keyPath] = CGFloat($1) },
            range: range, step: step)))
    }

    public static func choice(
        _ title: String, _ keyPath: WritableKeyPath<Document, String> & Sendable, options: [String]
    ) -> TokenKnob {
        TokenKnob(title: title, kind: .choice(keyPath, options: options))
    }

    public static func color(_ title: String, _ keyPath: WritableKeyPath<Document, TokenColor> & Sendable) -> TokenKnob {
        TokenKnob(title: title, kind: .color(keyPath))
    }
}

/// A color a host document carries: light and optional dark components in
/// sRGB, so it is Codable and readable back, unlike `Color`.
public struct TokenColor: Codable, Equatable, Sendable {
    public var light: ThemeTuning.RGB
    public var dark: ThemeTuning.RGB?

    public init(light: ThemeTuning.RGB, dark: ThemeTuning.RGB? = nil) {
        self.light = light
        self.dark = dark
    }

    /// The dynamic color: the dark value in dark appearance when present.
    public var color: Color {
        guard let dark else { return light.color }
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark.uiColor : light.uiColor
        })
    }
}

extension TokenDocument {
    /// The surface's store for this document, erased for the tool state.
    @MainActor static func makeStore() -> any AnyTokenStore { TokenStore<Self>() }
}

/// The surface's hold on a host document: the shared file store, the pages,
/// and reset. Erased so the tool state can hold any document.
@MainActor
protocol AnyTokenStore {
    var pageTitles: [String] { get }
    func page(_ index: Int) -> AnyView
    func reset()
    var exportJSON: String { get }
}

@MainActor
final class TokenStore<Document: TokenDocument>: AnyTokenStore {
    @Shared var document: Document

    /// The store over the document's file in Documents, or over `url` (a test's
    /// temporary file). A file that fails to decode (written by a newer
    /// version, or by hand) leaves the shipped document in place, is reported
    /// once in the log, and is not rewritten until a knob moves.
    init(url: URL? = nil) {
        let url = url ?? URL.documentsDirectory.appending(component: Document.fileName)
        _document = Shared(wrappedValue: Document.shipped, .fileStorage(url, decoder: nil, encoder: ThemeTuning.fileEncoder))
        if let error = $document.loadError {
            SurfaceLog.logger.error("\(Document.fileName, privacy: .public) did not decode, the shipped tokens apply: \(error)")
        }
        document.apply()
    }

    /// Whether the file failed to decode when the store opened.
    var loadFailed: Bool { $document.loadError != nil }

    var pageTitles: [String] { Document.pages.map(\.title) }

    func page(_ index: Int) -> AnyView {
        AnyView(TokenPageView(store: self, page: Document.pages[index]))
    }

    func reset() {
        $document.withLock { $0 = Document.shipped }
        document.apply()
    }

    var exportJSON: String {
        guard let data = try? ThemeTuning.fileEncoder.encode(document) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    func binding<Value>(_ keyPath: WritableKeyPath<Document, Value> & Sendable) -> Binding<Value> {
        Binding(
            get: { self.document[keyPath: keyPath] },
            set: { value in
                self.$document.withLock { $0[keyPath: keyPath] = value }
                self.document.apply()
            })
    }
}

/// One page of a host document as a Form section: every knob as its control.
struct TokenPageView<Document: TokenDocument>: View {
    let store: TokenStore<Document>
    let page: TokenPage<Document>

    var body: some View {
        Section(page.title) {
            ForEach(page.knobs) { knob in
                switch knob.kind {
                case .number(let number):
                    TokenNumberRow(
                        title: knob.title,
                        value: Binding(
                            get: { number.get(store.document) },
                            set: { value in
                                store.$document.withLock { number.set(&$0, value) }
                                store.document.apply()
                            }),
                        range: number.range, step: number.step)
                case .choice(let keyPath, let options):
                    // A value the options no longer list (an older file) stays
                    // selectable rather than leaving the picker blank.
                    let current = store.document[keyPath: keyPath]
                    let shown = options.contains(current) ? options : options + [current]
                    Picker(knob.title, selection: store.binding(keyPath)) {
                        ForEach(shown, id: \.self) { Text($0).tag($0) }
                    }
                case .color(let keyPath):
                    TokenColorRow(title: knob.title, value: store.binding(keyPath))
                }
            }
        }
    }
}

private struct TokenNumberRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(value, format: .number.precision(.fractionLength(step < 1 ? 2 : 0)))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            .font(.subheadline)
            Slider(value: $value, in: range, step: step) { Text(title) }
        }
    }
}

private struct TokenColorRow: View {
    let title: String
    @Binding var value: TokenColor

    var body: some View {
        ColorPicker(title, selection: Binding(
            get: { value.light.color },
            set: { value.light = ThemeTuning.RGB($0) }
        ), supportsOpacity: false)
        Toggle("\(title) in dark", isOn: Binding(
            get: { value.dark != nil },
            set: { value.dark = $0 ? (value.dark ?? value.light) : nil }))
        if value.dark != nil {
            ColorPicker("\(title), dark", selection: Binding(
                get: { (value.dark ?? value.light).color },
                set: { value.dark = ThemeTuning.RGB($0) }
            ), supportsOpacity: false)
        }
    }
}
#endif
