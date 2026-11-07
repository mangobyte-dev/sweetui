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
    r.add("TuneCardNotes") { TuneCardFixture(place: .notes) }
    r.add("TuneCardVersions") { TuneCardFixture(place: .versions) }
    r.add("TuneCardTokensAX") { TuneCardFixture(place: .tokens, accessibility: true) }
    r.add("TuneCardNotesAX") { TuneCardFixture(place: .notes, accessibility: true) }
    r.add("TuneCardVersionsAX") { TuneCardFixture(place: .versions, accessibility: true) }
}

/// Tune's card at its smallest: 300 × 260, or 300 × 360 at an accessibility
/// text size, where the place picker becomes a menu.
private struct TuneCardFixture: View {
    let place: DesignSurface.Place
    var accessibility = false

    var body: some View {
        DesignSurface.card(at: place)
            .frame(width: 300, height: accessibility ? 360 : 260)
            .dynamicTypeSize(accessibility ? .accessibility3 : .large)
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
