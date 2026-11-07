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
