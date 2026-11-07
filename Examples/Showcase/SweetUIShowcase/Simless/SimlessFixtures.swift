// SPDX-License-Identifier: MIT-0
// Copyright 2026 Abacus.AI, Inc. MIT No Attribution: you may use, copy, modify
// and distribute this file without restriction or attribution. Provided "as is",
// without warranty of any kind.

// Fixtures for `simless render`: each one builds a screen in a deterministic state.
// Created by `simless init`. This file is yours; edit it freely.
//
// Hot reload recompiles this file together with the edited view files, so
// fixtures always render the latest code. Keep it to view construction:
// seed data, environment objects, fixed dates, no network.
#if DEBUG && os(iOS)
import SweetUIDesignSurface
import SweetUIShowcaseFeature
import SwiftUI

@MainActor
func simlessFixtures(_ r: SimlessRegistry) {
    r.add("Catalog") { ContentView() }
    r.add("ContributionsActivity") { ContributionsActivity() }
    r.add("TunePanel") { TunePanelFixture(tuning: .default) }
    r.add("TunePanelEmerald") {
        var tuning = ThemeTuning.default
        tuning.accent = .green
        return TunePanelFixture(tuning: tuning)
    }
    r.add("TuneCardTokens") { TuneCardFixture(place: .tokens) }
    r.add("TuneCardTokensFull") { TuneCardFixture(place: .tokens, full: true) }
    r.add("TuneCardTokensItem") { TuneCardFixture(place: .tokens, sample: .selection) }
    r.add("TuneCardTokensItemFull") { TuneCardFixture(place: .tokens, sample: .selection, full: true) }
    r.add("TuneCardTokensTryingFull") { TuneCardFixture(place: .tokens, sample: .trying, full: true) }
    r.add("TuneCardNotes") { TuneCardFixture(place: .notes) }
    r.add("TuneCardNotesThread") { TuneCardFixture(place: .notes, sample: .conversation, tall: true) }
    r.add("TuneCardNotesTrying") { TuneCardFixture(place: .notes, sample: .trying, tall: true) }
    r.add("TuneCardTrying") { TuneCardFixture(place: .notes, sample: .trying) }
    r.add("TuneCardVersions") { TuneCardFixture(place: .versions) }
    r.add("TuneCardTokensAX") { TuneCardFixture(place: .tokens, accessibility: true) }
    r.add("TuneCardTokensItemAX") { TuneCardFixture(place: .tokens, sample: .selection, accessibility: true) }
    r.add("TuneCardNotesAX") { TuneCardFixture(place: .notes, accessibility: true) }
    r.add("TuneCardVersionsAX") { TuneCardFixture(place: .versions, accessibility: true) }
}

/// Tune's card at its smallest: 300 × 260, or 300 × 360 at an accessibility
/// text size, where the place picker becomes a menu; `tall` is the card a
/// phone opens at, for a conversation; `full` is a card tall enough to lay
/// out every row, pinned to the top, so the tree lists rows below the screen.
private struct TuneCardFixture: View {
    let place: DesignSurface.Place
    var sample = DesignSurface.CardSample.firstOpen
    var accessibility = false
    var tall = false
    var full = false

    var body: some View {
        DesignSurface.card(at: place, sample: sample)
            .frame(width: tall ? 360 : 300, height: full ? 2400 : tall ? 640 : accessibility ? 360 : 260)
            .dynamicTypeSize(accessibility ? .accessibility3 : .large)
            .frame(height: full ? 874 : nil, alignment: .top)
    }
}

/// The embedded panel over a fixed tuning, as the Showcase previews host it.
private struct TunePanelFixture: View {
    @State var tuning: ThemeTuning

    var body: some View {
        TuningPanel(tuning: $tuning)
            .registryTheme(tuning.theme)
    }
}
#endif
