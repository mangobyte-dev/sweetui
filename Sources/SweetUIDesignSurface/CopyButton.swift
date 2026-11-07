#if canImport(UIKit)
import SwiftUI
import UIKit

/// Puts text on the pasteboard and reads "Copied" for 2 s. The label style at
/// the call site decides whether the title shows; assistive technology
/// always has it.
public struct CopyButton: View {
    let title: LocalizedStringKey
    let text: String
    @State private var didCopy = false

    public init(_ title: LocalizedStringKey, text: String) {
        self.title = title
        self.text = text
    }

    public var body: some View {
        Button(didCopy ? "Copied" : title, systemImage: didCopy ? "checkmark" : "doc.on.doc", action: copy)
            .contentTransition(.symbolEffect(.replace))
            .task(id: didCopy) {
                guard didCopy else { return }
                do {
                    try await Task.sleep(for: .seconds(2))
                } catch {
                    return
                }
                didCopy = false
            }
    }

    private func copy() {
        UIPasteboard.general.string = text
        didCopy = true
        AccessibilityNotification.Announcement("Copied.").post()
    }
}
#endif
