import SwiftUI
import SweetUIDesignSurface

/// The tuning strip that stays above the tab bar on every screen: the named
/// accents one tap away and the Tune button for the full panel, so a change
/// lands on the demo behind it without leaving the screen, the way shadcn's
/// customizer sits beside its preview. When the tab bar minimizes on scroll
/// only the button remains.
struct TuningAccessory: View {
    @Binding var tuning: ThemeTuning
    @Binding var isTuning: Bool
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        HStack(spacing: 8) {
            if placement != .inline {
                ScrollView(.horizontal) {
                    HStack(spacing: 4) {
                        ForEach(ThemeTuning.Accent.named) { accent in
                            AccentSwatch(
                                accent: accent,
                                isSelected: tuning.accent == accent,
                                custom: tuning.customAccent,
                                diameter: 22
                            ) {
                                withAnimation(.snappy) { tuning.accent = accent }
                            }
                            .accessibilityIdentifier("tune.accent.\(accent.rawValue)")
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            Button("Tune", systemImage: "slider.horizontal.3") {
                withAnimation(.snappy) { isTuning.toggle() }
            }
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
    }
}
