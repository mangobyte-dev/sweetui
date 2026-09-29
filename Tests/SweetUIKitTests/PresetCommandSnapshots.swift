import Foundation
import InlineSnapshotTesting
import Testing

@testable import SweetUIKit

extension Commands {
  @Test func presetCommandSnapshots() throws {
    let fs = try fixture()
    try withFixture(fs) {
      let output0 = try command(["preset", "decode", "a13GkaOXWwIF"])
      #expect(output0.code == 0)
      assertInlineSnapshot(of: output0.stdout, as: .lines) {
        """
        Preset
          code                      a13GkaOXWwIF
          version                   a
          accent                    indigo
          darkLabelOnAccent         false
          surfaceOpacity            0.055
          borderOpacity             0.08
          borderWidth               1.0
          emphasizedBorderWidth     2.0
          compactRadius             6.0
          controlRadius             8.0
          cardRadius                16.0
          compactSpacing            8.0
          standardSpacing           16.0
          sectionSpacing            24.0
          controlHorizontalPadding  12.0
          disabledOpacity           0.5
          url                       https://sweetui.dev/create?preset=a13GkaOXWwIF

        let theme = RegistryTheme(
            accent: .indigo,
            onAccent: .white,
            surface: .primary.opacity(0.055),
            border: .primary.opacity(0.080),
            disabledOpacity: 0.500,
            metrics: RegistryMetrics(
                compactSpacing: 8,
                standardSpacing: 16,
                sectionSpacing: 24,
                controlHorizontalPadding: 12,
                borderWidth: 1,
                emphasizedBorderWidth: 2,
                compactRadius: 6,
                controlRadius: 8,
                cardRadius: 16
            )
        )

        // Apply once at the root of your scene; every registry item below inherits it.
        ContentView()
            .registryTheme(theme)

        """
      }
      let output1 = try command(["preset", "url", "a13GkaOXWwIF"])
      #expect(output1.code == 0)
      assertInlineSnapshot(of: output1.stdout, as: .lines) {
        """
        https://sweetui.dev/create?preset=a13GkaOXWwIF

        """
      }
      let output2 = try command(["preset", "apply", "a13GkaOXWwIF", "--destination", "/app"])
      #expect(output2.code == 0)
      assertInlineSnapshot(of: output2.stdout, as: .lines) {
        """
        wrote /app/RegistryTheme+App.swift
        apply once at the scene root: ContentView().registryTheme(.app)

        """
      }
      let output3 = try command(["preset", "resolve", "/app"])
      #expect(output3.code == 0)
      assertInlineSnapshot(of: output3.stdout, as: .lines) {
        """
        Preset
          code                      a13GkaOXWwIF
          version                   a
          accent                    indigo
          darkLabelOnAccent         false
          surfaceOpacity            0.055
          borderOpacity             0.08
          borderWidth               1.0
          emphasizedBorderWidth     2.0
          compactRadius             6.0
          controlRadius             8.0
          cardRadius                16.0
          compactSpacing            8.0
          standardSpacing           16.0
          sectionSpacing            24.0
          controlHorizontalPadding  12.0
          disabledOpacity           0.5
          url                       https://sweetui.dev/create?preset=a13GkaOXWwIF

        let theme = RegistryTheme(
            accent: .indigo,
            onAccent: .white,
            surface: .primary.opacity(0.055),
            border: .primary.opacity(0.080),
            disabledOpacity: 0.500,
            metrics: RegistryMetrics(
                compactSpacing: 8,
                standardSpacing: 16,
                sectionSpacing: 24,
                controlHorizontalPadding: 12,
                borderWidth: 1,
                emphasizedBorderWidth: 2,
                compactRadius: 6,
                controlRadius: 8,
                cardRadius: 16
            )
        )

        // Apply once at the root of your scene; every registry item below inherits it.
        ContentView()
            .registryTheme(theme)

        """
      }
    }
  }
}
