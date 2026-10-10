import CustomDump
import Dependencies
import Foundation
import Testing

@testable import SweetUIKit

/// The recipe set is the value gate: an item that merely renames a native control is guidance.
private let recipeNames: Set<String> = [
  "aspect-ratio", "direction", "native-select", "radio-group", "slider", "switch", "tabs",
  "alert-dialog", "calendar", "collapsible", "context-menu", "dialog", "drawer", "dropdown-menu",
  "popover", "scroll-area", "sidebar", "tooltip",
  "carousel", "chart-tooltip", "date-picker", "input-otp", "menubar", "sheet", "typography",
  "fold-arrangement",
]

private func previewSource(_ registry: Registry, _ name: String) throws -> String {
  try repositoryText("Registry/" + registry.items[name]!["preview"]["source"].text)
}

/// What a caller receives for a recipe: the snippet in `usage` plus the prose in `docs`,
/// exactly what install prints and the catalog page renders.
private func guidance(_ registry: Registry, _ name: String) -> String {
  let item = registry.items[name]!
  return item["usage"].text + "\n\n" + item["docs"].text
}

extension Commands {
  @Test func nativeSeamsInstallInsteadOfWrapperViews() throws {
    try withRepository {
      let installer = try Installer(root: repositoryRoot)
      for (name, closure, file, present, absent) in [
        (
          "button", ["button"], "RegistryButtonStyle.swift",
          ["public struct RegistryButtonStyle: ButtonStyle"], "struct RegistryButton: View"
        ),
        (
          "badge", ["badge"], "RegistryBadge.swift", ["func registryBadge("],
          "struct RegistryBadge: View"
        ),
        (
          "button-group", ["button", "button-group"], "RegistryButtonGroupStyle.swift",
          [
            "public struct RegistryButtonGroupStyle: ControlGroupStyle",
            "HStack(spacing: theme.metrics.compactSpacing)", "configuration.content",
            "RegistryButtonStyle(variant)",
          ], "struct RegistryButtonGroup: View"
        ),
        (
          "card", ["card"], "RegistryCardStyle.swift",
          ["public struct RegistryCardStyle: GroupBoxStyle"], "struct RegistryCard: View"
        ),
      ] {
        expectNoDifference(try installer.registry.resolve(name), closure)
        try withTemporaryDirectory { destination in
          let installed = try installer.install(name, destination: destination)
          #expect(installed.count == closure.count, "\(name)")
          let source = try fileText(destination + "/" + file)
          for marker in present { #expect(source.contains(marker), "\(name): \(marker)") }
          #expect(!source.contains(absent), "\(name)")
        }
      }
    }
  }

  @Test func schemaDeclaresEveryTopLevelItemField() throws {
    let schema = try JSON.read(repositoryData("Registry/schema.json"))
    let declared = Set(try #require(schema["properties"].object).keys)
    let items = repositoryRoot + "/Registry/items"
    for name in try directoryEntries(items) where name.hasSuffix(".json") {
      let fields = Set(try #require(JSON.read(fileData(items + "/" + name)).object).keys)
      #expect(
        fields.subtracting(declared).isEmpty,
        "The canonical schema forbids undeclared item fields: \(name)")
    }
    // Without "required": ["kind"], a kind-less document vacuously matches the recipe
    // branch under JSON Schema 2020-12, so external validators of this canonical schema
    // report recipe-only errors on non-recipe drafts.
    let conditional = schema["allOf"].array?.first?["if"] ?? .null
    #expect(conditional["required"].strings.contains("kind"))
    #expect(conditional["properties"]["kind"]["const"] == "recipe")
  }

  @Test func previewMetadataResolvesToDeclaredSource() throws {
    try withRepository {
      let registry = try Registry(root: repositoryRoot)
      for (name, item) in registry.items where item["kind"] != "recipe" {
        let preview = "#Preview(\"\(item["preview"]["name"].text)\")"
        #expect(try previewSource(registry, name).contains(preview), "\(name)")
      }
    }
  }

  @Test func stageOneItemsKeepTheirNativeSeams() throws {
    let markers = [
      "aspect-ratio": ".aspectRatio(", "badge": "func registryBadge(", "button": "ButtonStyle",
      "button-group": "ControlGroupStyle", "card": "GroupBoxStyle", "checkbox": "ToggleStyle",
      "input": "TextFieldStyle", "label": "LabelStyle", "progress": "ProgressViewStyle",
      "radio-group": ".pickerStyle(.inline)", "select": ".pickerStyle(.menu)",
      "separator": "func registrySeparator(", "slider": ".controlSize(",
      "spinner": "ProgressViewStyle", "switch": ".toggleStyle(.switch)",
      "tabs": ".pickerStyle(.segmented)", "textarea": "func registryTextArea(",
      "toggle": "ToggleStyle", "toggle-group": "func registryToggleGroup(",
      "native-select": ".pickerStyle(.menu)", "direction": "layoutDirection",
    ]
    try withRepository {
      let registry = try Registry(root: repositoryRoot)
      // The Stage 1 names are the keys of `markers`; the roadmap that once listed them
      // left the repository for the beta (docs/component-roadmap.md moved out).
      for name in markers.keys {
        let item = try #require(registry.items[name])
        let recipe = item["kind"] == "recipe"
        let evidence = recipe ? guidance(registry, name) : try previewSource(registry, name)
        #expect(evidence.contains(try #require(markers[name])), "\(name)")
        #expect(!evidence.contains(/public struct \w+: View/), "\(name)")
        if recipe { continue }
        for marker in [
          "preferredColorScheme(.dark)", "layoutDirection", "dynamicTypeSize(.accessibility",
        ] { #expect(evidence.contains(marker), "\(name): \(marker)") }
      }
    }
  }

  @Test func valueGateSeparatesRecipesFromInstallableItems() throws {
    try withRepository {
      let registry = try Registry(root: repositoryRoot)
      let kinds = registry.items.mapValues { $0["kind"].text }
      #expect(Set(kinds.filter { $0.value == "recipe" }.keys) == recipeNames)
      #expect(kinds.values.filter { $0 == "component" }.count == 39)
      #expect(kinds.values.filter { $0 == "block" }.count == 11)
    }
  }

  @Test func recipesFailLoudlyWithTheirGuidance() throws {
    try withRepository {
      let installer = try Installer(root: repositoryRoot)
      let caught = #expect(throws: RecipeGuidance.self) {
        _ = try installer.registry.resolve("tabs")
      }
      #expect(caught?.docs.contains(".pickerStyle(.segmented)") == true)
      try withTemporaryDirectory { destination in
        #expect(throws: RecipeGuidance.self) {
          _ = try installer.install("tabs", destination: destination)
        }
        #expect(try directoryEntries(destination).isEmpty)
        let result = try command(["install", "switch", "--destination", destination])
        #expect(result.code == 2)
        #expect(result.stdout.contains(".toggleStyle(.switch)"))
        #expect(result.stderr.contains("recipe items are native guidance; nothing to install"))
        #expect(try directoryEntries(destination).isEmpty)
        let planned = try command(["install", "switch", "--plan", "--destination", destination])
        #expect(planned.code == 0)
        #expect(planned.stdout.contains(".toggleStyle(.switch)"))
        #expect(
          planned.stdout.contains(
            "plan: switch is a recipe; native guidance only; nothing installs"))
        #expect(try directoryEntries(destination).isEmpty)
      }
    }
  }

  @Test func accessibilityContractsStayInSource() throws {
    try withRepository {
      let registry = try Registry(root: repositoryRoot)
      let textarea = try previewSource(registry, "textarea")
      #expect(textarea.contains("accessibilityLabel: Text"))
      #expect(textarea.contains(".accessibilityLabel(accessibilityLabel)"))
      let aspectRatio = guidance(registry, "aspect-ratio")
      #expect(aspectRatio.contains(".accessibilityHidden(true)"))
      #expect(aspectRatio.contains(".accessibilityLabel(\"Video placeholder\")"))
      #expect(aspectRatio.contains(".accessibilityLabel(\"Avatar placeholder\")"))
      let slider = guidance(registry, "slider")
      #expect(slider.contains(".tint(_:)"))
      #expect(slider.contains(".controlSize(_:)"))
      #expect(slider.components(separatedBy: ".accessibilityHidden(true)").count == 3)
      #expect(!slider.contains("registrySlider"))
      for name in ["input", "textarea"] {
        let source = try previewSource(registry, name)
        #expect(source.contains(".foregroundStyle(theme.negative)"), "\(name)")
        #expect(!source.contains(".foregroundStyle(.red)"), "\(name)")
      }
      for (state, name, marker) in [
        ("enabled", "button", "isEnabled"), ("pressed", "button", "configuration.isPressed"),
        ("focused", "input", "isFocused"), ("selected", "checkbox", "isSelected"),
        ("disabled", "button", ".disabled(true)"), ("invalid", "input", "isInvalid"),
      ] { #expect(try previewSource(registry, name).contains(marker), "\(state): \(name)") }
    }
  }

  @Test func everyFoundationTokenHasTwoSemanticConsumers() throws {
    // The accent reaches items indirectly: the registryTheme modifier applies it as the
    // subtree tint, and items read the tint.
    let contract: [String: (String, [String])] = [
      "accent": ("TintShapeStyle()", ["badge", "button"]),
      "onAccent": ("theme.onAccent", ["button", "auth-form"]),
      "surface": ("theme.surface", ["badge", "input"]),
      "border": ("theme.border", ["badge", "separator"]),
      "positive": ("theme.positive", ["badge", "progress"]),
      "negative": ("theme.negative", ["badge", "button"]),
      "disabledOpacity": (
        "theme.disabledOpacity", ["button", "checkbox", "input", "select", "textarea"]
      ),
      "compactSpacing": ("theme.metrics.compactSpacing", ["badge", "label"]),
      "standardSpacing": ("theme.metrics.standardSpacing", ["card", "metric-card"]),
      "sectionSpacing": (
        "theme.metrics.sectionSpacing", ["finance-overview", "nutrition-overview"]
      ),
      "controlHorizontalPadding": ("theme.metrics.controlHorizontalPadding", ["input", "select"]),
      "borderWidth": (
        "theme.metrics.borderWidth", ["badge", "button", "checkbox", "input", "select", "textarea"]
      ),
      "emphasizedBorderWidth": ("theme.metrics.emphasizedBorderWidth", ["input", "textarea"]),
      "compactRadius": ("theme.metrics.compactRadius", ["badge", "checkbox"]),
      "controlRadius": ("theme.metrics.controlRadius", ["button", "input", "select", "textarea"]),
      "cardRadius": (".registrySurface()", ["card", "metric-card"]),
      "minimumHitSize": ("RegistryMetrics.minimumHitSize", ["button", "checkbox", "select"]),
    ]
    let foundations = try repositoryText("Sources/SweetUIFoundations/RegistryTheme.swift")
    let tokens = Set(
      foundations.matches(of: /public (?:var|static let) (\w+):/).map { String($0.1) }
    ).subtracting([
      "metrics", "presets", "name", "theme", "id",
      // The Create studio fields (D4, slice 7) are theme inputs the root modifier
      // applies once, not per-item semantic tokens, so they are outside the
      // two-consumer token inventory; chartPalette is read only by the chart item.
      "fontDesign", "surfaceOpacity", "surfaceStep", "chartPalette", "background", "foreground",
      "secondaryForeground",
    ])
    #expect(Set(contract.keys) == tokens)
    try withRepository {
      let registry = try Registry(root: repositoryRoot)
      for (token, (marker, names)) in contract {
        #expect(names.count >= 2, "\(token)")
        for name in names {
          #expect(try previewSource(registry, name).contains(marker), "\(token): \(name)")
        }
      }
    }
  }

  @Test func showcaseInstallsExactCanonicalSources() throws {
    let destination =
      repositoryRoot
      + "/Examples/Showcase/SweetUIShowcasePackage/Sources/SweetUIShowcaseFeature/Installed"
    try withRepository {
      let registry = try Registry(root: repositoryRoot)
      for (name, item) in registry.items {
        for file in item["files"].array ?? [] {
          let target = destination + "/" + file["target"].text
          #expect(FileManager.default.fileExists(atPath: target), "\(name): \(target)")
          #expect(
            try fileData(target) == repositoryData("Registry/" + file["source"].text),
            "\(name): \(file["target"].text)")
        }
      }
    }
  }

  @Test func blocksResolveTheirComponentsFirstAndKeepTheirContracts() throws {
    try withRepository {
      let registry = try Registry(root: repositoryRoot)
      expectNoDifference(
        try registry.resolve("finance-overview"),
        ["metric-card", "transaction-row", "empty", "finance-overview"])
      expectNoDifference(
        try registry.resolve("nutrition-overview"),
        ["metric-card", "macro-progress", "nutrition-overview"])
      expectNoDifference(
        try registry.resolve("auth-form"), ["input", "button", "card", "auth-form"])
      expectNoDifference(
        try registry.resolve("settings-section"),
        ["select", "separator", "button", "settings-section"])
      // A copy that drops autofill content types, the error announcement, or the submit
      // guard would still render but silently lose what the block standardizes.
      let auth = try previewSource(registry, "auth-form")
      for marker in [
        ".textContentType(.username)", ".textContentType(.password)",
        "AccessibilityNotification.Announcement", ".submitLabel(.next)", ".submitLabel(.go)",
        "RegistryInputStyle(isInvalid:", ".foregroundStyle(theme.negative)", "if !isSubmitting",
      ] { #expect(auth.contains(marker), "\(marker)") }
      #expect(!auth.contains(".foregroundStyle(.red)"))
      // An enabled row must clear its explanation; the explanation is visible text, never
      // a hint that double-announces, and the block declares no state of its own.
      let settings = try previewSource(registry, "settings-section")
      for marker in [
        ".toggleStyle(.switch)", ".accessibilityAddTraits(.isHeader)", "Group(subviews: content)",
        "Divider().registrySeparator()", "@Entry var settingsRowDescription",
        "isDisabled ? explanation : nil",
      ] { #expect(settings.contains(marker), "\(marker)") }
      #expect(!settings.contains("accessibilityHint"))
      #expect(!settings.components(separatedBy: "#if DEBUG")[0].contains("@State private"))
    }
  }

  @Test func installRecordsExactProvenance() throws {
    try withRepository {
      let installer = try Installer(root: repositoryRoot)
      try withTemporaryDirectory { destination in
        let installed = try installer.install("finance-overview", destination: destination)
        #expect(installed.count == 4)
        for file in installed { #expect(try fileData(file.target) == fileData(file.source)) }
        let receipt = try JSON.read(fileData(destination + "/.sweetui/receipt.json"))
        #expect(receipt["schemaVersion"] == 1)
        #expect(receipt["items"]["finance-overview"]["version"] == "0.4.3")
        #expect(
          receipt["items"]["finance-overview"]["packageDependencies"] == [
            [
              "package": "SweetUI", "product": "SweetUIFoundations",
              "requirement": "0.x",
              "sourceURL": "https://github.com/mangobyte-dev/sweetui.git",
              "swiftPM": ["kind": "upToNextMinor", "minimumVersion": "0.5.0"],
            ]
          ])
        #expect(
          Set(receipt["files"].object?.keys.map { $0 } ?? []) == [
            "MetricCard.swift", "TransactionRow.swift", "RegistryEmptyStateModifier.swift",
            "FinanceOverview.swift",
          ])
        let metadata = try FileManager.default.subpathsOfDirectory(
          atPath: destination + "/.sweetui")
        #expect(!metadata.contains { $0.hasSuffix(".swift") })
        // The consumer receives the package URL, resolvable requirement, and product.
        let button = try command(["install", "button", "--destination", destination])
        #expect(button.code == 0)
        #expect(
          button.stdout.contains(
            "requires: add package https://github.com/mangobyte-dev/sweetui.git (from 0.5.0 up to the next minor version) and link product SweetUIFoundations"
          ))
      }
    }
  }

  @Test func modifiedOwnedSourceIsRefusedNamingTheRecoveryFlags() throws {
    try withRepository {
      let installer = try Installer(root: repositoryRoot)
      try withTemporaryDirectory { destination in
        _ = try installer.install("metric-card", destination: destination)
        #expect(try installer.install("metric-card", destination: destination) == [])
        let owned = destination + "/MetricCard.swift"
        try "// consumer edit\n".write(toFile: owned, atomically: true, encoding: .utf8)
        let caught = #expect(throws: RegistryError.self) {
          _ = try installer.install("metric-card", destination: destination)
        }
        #expect(caught?.description.contains("Refusing to overwrite owned source") == true)
        // A safety refusal, not a syntax mistake: no usage block, and the recovery flags named.
        let result = try command(["install", "metric-card", "--destination", destination])
        #expect(result.code == 2)
        #expect(result.stderr.contains("Refusing to overwrite owned source"))
        for flag in ["--diff", "--update", "--force"] { #expect(result.stderr.contains(flag)) }
        #expect(!result.stderr.contains("usage:"))
        #expect(try fileText(owned) == "// consumer edit\n")
      }
    }
  }

  @Test func diffAuditsOwnedSourceAgainstCanonicalSource() throws {
    try withRepository {
      let installer = try Installer(root: repositoryRoot)
      try withTemporaryDirectory { destination in
        _ = try installer.install("metric-card", destination: destination)
        let identical = try command([
          "install", "metric-card", "--diff", "--destination", destination,
        ])
        #expect(identical.code == 0)
        #expect(identical.stdout.contains("identical metric-card: \(destination)/MetricCard.swift"))
        let owned = destination + "/MetricCard.swift"
        try (fileText(owned) + "// consumer edit\n").write(
          toFile: owned, atomically: true, encoding: .utf8)
        let changed = try command([
          "install", "metric-card", "--diff", "--destination", destination,
        ])
        #expect(changed.code == 1)
        #expect(changed.stdout.contains("--- owned/MetricCard.swift"))
        #expect(changed.stdout.contains("+++ incoming/sources/components/MetricCard.swift"))
        #expect(changed.stdout.contains("@@"))
        #expect(changed.stdout.contains("-// consumer edit"))
      }
    }
  }

  @Test func plainInstallPreservesALocallyModifiedReceipt() throws {
    // install, local edit, --update, plain install: the plain install writes nothing for an
    // unchanged closure, so it must not reset the locally-modified installedDigest to the
    // source digest for content that is not on disk, which would make the next identical
    // install falsely refuse as an overwrite.
    try withRepository {
      let installer = try Installer(root: repositoryRoot)
      try withTemporaryDirectory { destination in
        _ = try installer.install("badge", destination: destination)
        let target = destination + "/RegistryBadge.swift"
        let local = try fileData(target) + Data("// local edit\n".utf8)
        try local.write(to: URL(fileURLWithPath: target))
        #expect(
          try installer.update("badge", destination: destination).map(\.status.rawValue)
            == ["locally-modified"])
        func record() throws -> JSON {
          try JSON.read(fileData(destination + "/.sweetui/receipt.json"))["files"][
            "RegistryBadge.swift"]
        }
        let afterUpdate = try record()
        #expect(afterUpdate["installedDigest"].text == Installer.digest(local))
        #expect(afterUpdate["installedDigest"] != afterUpdate["sourceDigest"])
        for _ in 0..<2 {
          #expect(try installer.install("badge", destination: destination) == [])
          #expect(try fileData(target) == local)
          expectNoDifference(try record(), afterUpdate)
        }
      }
    }
  }

  @Test func planPrintsTheClosureStatusesAndPackageLines() throws {
    try withRepository {
      try withTemporaryDirectory { destination in
        let result = try command([
          "install", "finance-overview", "--plan", "--destination", destination,
        ])
        #expect(result.code == 0)
        #expect(
          result.stdout.contains(
            "closure:\n  metric-card 0.2.2 (component)\n  transaction-row 0.5.1 (component)\n  empty 0.1.1 (component)\n  finance-overview 0.4.3 (block)\n"
          ))
        #expect(
          result.stdout.contains(
            "files:\n  new metric-card: \(destination)/MetricCard.swift\n  new transaction-row: \(destination)/TransactionRow.swift\n  new empty: \(destination)/RegistryEmptyStateModifier.swift\n  new finance-overview: \(destination)/FinanceOverview.swift\n"
          ))
        #expect(
          result.stdout.contains(
            "  requires: add package https://github.com/mangobyte-dev/sweetui.git (from 0.5.0 up to the next minor version) and link product SweetUIFoundations"
          ))
        #expect(result.stdout.contains("  ok: no collisions"))
        #expect(result.stdout.contains("next steps:"))
        #expect(result.stdout.contains("plan only: nothing was written"))
        #expect(try directoryEntries(destination).isEmpty)
      }
    }
  }

  @Test func planStatusesTrackReceiptAndRegistryState() throws {
    let fs = try fixture("base\n")
    try withFixture(fs) {
      let installer = try Installer(root: "/registry")
      _ = try installer.install("example", destination: "/app")
      func statuses() throws -> [String] {
        try installer.inspectPlan("example", destination: "/app").map(\.status.rawValue)
      }
      #expect(try statuses() == ["up-to-date"])
      try fs.put("/app/Example.swift", "consumer\n")
      #expect(try statuses() == ["modified-would-require-force"])
      try fs.put("/app/Example.swift", "base\n")
      try fs.put("/registry/Registry/sources/Example.swift", "registry\n")
      #expect(try statuses() == ["would-merge"])
      #expect(
        try installer.update("example", destination: "/app").map(\.status.rawValue) == ["updated"])
      #expect(try fs.read("/app/Example.swift") == Data("registry\n".utf8))
      #expect(try statuses() == ["up-to-date"])
    }
  }

  @Test func searchRanksNamesAliasesAndPlatformFloors() throws {
    try withRepository {
      let registry = try Registry(root: repositoryRoot)
      let exact = try registry.search("finance-overview")
      #expect(exact.first?["name"] == "finance-overview")
      #expect((exact.first?["score"].number ?? 0) > 100)
      #expect(
        try registry.search("nutrition dashboard", kind: "block").map { $0["name"].text } == [
          "nutrition-overview"
        ])
      #expect(
        try registry.search("finance-overview", platform: "iOS", targetVersion: "26").first?[
          "name"] == "finance-overview")
      #expect(try registry.search("finance", platform: "iOS", targetVersion: "25.0").isEmpty)
      // Observed misses drive aliases: "dropdown" is what a web developer types for a Menu;
      // it must find the recipe first, and an alias must never leak onto another item.
      let dropdown = try registry.search("dropdown")
      #expect(dropdown.first?["name"] == "dropdown-menu")
      #expect(dropdown.first?["aliases"].strings.contains("dropdown") == true)
      let shimmer = try registry.search("shimmer")
      #expect(shimmer.first?["name"] == "skeleton")
      #expect(!shimmer.map { $0["name"].text }.contains("dropdown-menu"))
      let result = try command(["search", "finance", "--kind", "block", "--format", "json"])
      #expect(result.code == 0)
      let matches = try #require(JSON.read(Data(result.stdout.utf8)).array)
      #expect(matches.map { $0["name"].text } == ["finance-overview"])
      expectNoDifference(
        matches[0]["registryDependencies"], ["metric-card", "transaction-row", "empty"])
      #expect(!matches[0]["accessibility"].strings.isEmpty)
    }
  }
}

extension Commands {
  // An installable item whose source declares no public initializer, function, or static member
  // cannot be composed from `describe`; every one must name at least one.
  @Test func everyInstallableItemDescribesAtLeastOnePublicSignature() throws {
    try withRepository {
      let registry = try Registry(root: repositoryRoot)
      for name in registry.items.keys.sorted() where registry.items[name]!["kind"] != "recipe" {
        let described = try describeItem(name, registry: registry, fs: .local, root: repositoryRoot)
        #expect(!(described["signatures"].array ?? []).isEmpty, "\(name)")
      }
    }
  }
}
