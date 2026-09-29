import SwiftUI
import SweetUIFoundations

// Each demo renders the item's real `usage` snippet (plus its other variants)
// against the installed registry source, on the registry surface.

struct BubbleDemo: View {
    var body: some View {
        DemoSurface {
            Text("Are we still on for Thursday?")
                .registryBubble(.incoming)
            Text("Yes, 6pm works. I will bring the documents.")
                .registryBubble(.outgoing)
            Text("Maya added Omar to the conversation.")
                .registryBubble(.muted)
        }
    }
}

struct MessageDemo: View {
    var body: some View {
        DemoSurface {
            MessageRow(
                author: Text(verbatim: "Maya Khalid"),
                timestamp: Text(verbatim: "09:41"),
                status: Text("Delivered")
            ) {
                Avatar(initials: "MK", accessibilityLabel: Text(verbatim: "Maya Khalid"))
            } content: {
                Text("Are we still on for Thursday?")
            }

            MessageRow(timestamp: Text(verbatim: "09:42"), status: Text("Delivered")) {
                Text("Yes, 6pm works. I will bring the documents.")
            }
            .registryVariant(.outgoing)
        }
    }
}

private struct ChatTurn: Identifiable, Hashable {
    let id: Int
    let text: String
    let isMine: Bool
}

struct MessageScrollerDemo: View {
    @Environment(\.registryTheme) private var theme

    @State private var turns: [ChatTurn]
    @State private var position: Int?
    @State private var isFollowing = true
    @State private var draft = ""
    @State private var nextID: Int
    @State private var oldestID: Int

    init() {
        let seeded = (0 ..< 12).map { index in
            ChatTurn(
                id: index,
                text: "Message number \(index + 1) in the thread.",
                isMine: index.isMultiple(of: 2)
            )
        }
        _turns = State(initialValue: seeded)
        _nextID = State(initialValue: 12)
        _oldestID = State(initialValue: 0)
    }

    var body: some View {
        VStack(spacing: theme.metrics.standardSpacing) {
            MessageScroller(position: $position, isFollowing: $isFollowing, onReachTop: loadEarlier) {
                ForEach(turns) { turn in
                    row(for: turn).id(turn.id)
                }
            }
            .frame(height: 360)
            .registrySurface()

            HStack {
                Button("Load earlier messages", action: loadEarlier)
                    .buttonStyle(.registryOutline)
                    .accessibilityLabel("Load earlier messages")
                Spacer()
                Button("Jump to latest") {
                    if let last = turns.last { position = last.id }
                }
                .buttonStyle(.registryOutline)
                .accessibilityLabel("Jump to latest")
            }

            HStack(spacing: theme.metrics.compactSpacing) {
                TextField("Message", text: $draft)
                    .textFieldStyle(.registryInput)
                    .accessibilityLabel("Message")
                Button("Send", action: send)
                    .buttonStyle(.registry)
                    .accessibilityLabel("Send")
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    @ViewBuilder
    private func row(for turn: ChatTurn) -> some View {
        if turn.isMine {
            MessageRow {
                Text(turn.text)
            }
            .registryVariant(.outgoing)
        } else {
            MessageRow {
                Avatar(initials: "OA", accessibilityLabel: Text(verbatim: "Omar Ali"))
            } content: {
                Text(turn.text)
            }
        }
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let turn = ChatTurn(id: nextID, text: text, isMine: true)
        turns.append(turn)
        nextID += 1
        draft = ""
        position = turn.id
    }

    private func loadEarlier() {
        var older: [ChatTurn] = []
        for _ in 0 ..< 5 {
            oldestID -= 1
            older.append(
                ChatTurn(
                    id: oldestID,
                    text: "Earlier message \(oldestID).",
                    isMine: oldestID.isMultiple(of: 2)
                )
            )
        }
        turns.insert(contentsOf: older.reversed(), at: 0)
    }
}
