// Hand-written stand-ins for the names the generated `UsageSnippetChecks.swift`
// treats as the consumer's own code: the state, data, and helpers a usage
// snippet quotes but leaves for the adopter to supply. Each is minimal and
// internal so a snippet type-checks against a realistic shape without pulling in
// a whole demo. Add a line here when a snippet starts quoting a new such name.
//
// `nonisolated(unsafe)` marks the two globals a snippet mutates or holds by a
// non-Sendable type; the stand-ins are never executed, only compiled against.

import Foundation
import SwiftUI

// breadcrumb: the navigation path its items push onto and pop.
nonisolated(unsafe) var path = NavigationPath()

// chart: the plotted rows, read as `row.month`, `row.visits`, `row.channel`.
struct UsageSnippetChartRow: Identifiable {
    let id = UUID()
    let month: String
    let visits: Int
    let channel: String
}
let data: [UsageSnippetChartRow] = []

// command-search: the prepared sections it lists.
nonisolated(unsafe) let sections: [CommandSection<String>] = []

// table: the invoice rows (`line.item`, `line.quantity`, `line.amount`) and their total.
struct UsageSnippetInvoiceLine: Identifiable {
    let id = UUID()
    let item: String
    let quantity: Int
    let amount: Decimal
}
let lines: [UsageSnippetInvoiceLine] = []
let total = Decimal.zero

// skeleton: the real content the skeleton stands in for while loading.
struct ActivityRows: View {
    var body: some View { EmptyView() }
}

// toast: the screen the toast presents over, and the undo handler it calls.
struct CardDetail: View {
    var body: some View { EmptyView() }
}
func restoreMessage() {}

// message-scroller: the conversation rows (`message.id`, `message.text`, `message.isMine`).
struct UsageSnippetMessage: Identifiable {
    let id: String
    let text: String
    let isMine: Bool
}
let messages: [UsageSnippetMessage] = []
