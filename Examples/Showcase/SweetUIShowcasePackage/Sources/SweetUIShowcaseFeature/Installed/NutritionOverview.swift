import Foundation
import SwiftUI
import SweetUIFoundations

/// Prepared display data for one macronutrient in ``NutritionOverview``.
public struct NutritionMacroItem<ID: Hashable>: Identifiable {
    public let id: ID
    public let name: LocalizedStringResource
    public let value: Text
    public let target: Text
    public let progress: Double
    public let systemImage: String
    public let tint: Color

    public init(
        id: ID,
        name: LocalizedStringResource,
        value: Text,
        target: Text,
        progress: Double,
        systemImage: String,
        tint: Color
    ) {
        self.id = id
        self.name = name
        self.value = value
        self.target = target
        self.progress = progress
        self.systemImage = systemImage
        self.tint = tint
    }
}

/// A source-owned nutrition block that composes prepared energy and macro values.
public struct NutritionOverview<ID: Hashable>: View {
    @Environment(\.registryTheme) private var theme

    private let title: LocalizedStringResource
    private let energyTitle: LocalizedStringResource
    private let energy: Text
    private let energyDetail: Text
    private let sectionTitle: LocalizedStringResource
    private let macros: [NutritionMacroItem<ID>]
    private let actionTitle: LocalizedStringResource
    private let onLogFood: () -> Void

    public init(
        _ title: LocalizedStringResource,
        energyTitle: LocalizedStringResource,
        energy: Text,
        energyDetail: Text,
        sectionTitle: LocalizedStringResource,
        macros: [NutritionMacroItem<ID>],
        actionTitle: LocalizedStringResource,
        onLogFood: @escaping () -> Void
    ) {
        self.title = title
        self.energyTitle = energyTitle
        self.energy = energy
        self.energyDetail = energyDetail
        self.sectionTitle = sectionTitle
        self.macros = macros
        self.actionTitle = actionTitle
        self.onLogFood = onLogFood
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.sectionSpacing) {
            Text(title)
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)

            MetricCard(
                energyTitle,
                value: energy,
                detail: energyDetail,
                systemImage: "flame.fill"
            )

            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text(sectionTitle)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: theme.metrics.standardSpacing) {
                    ForEach(macros) { macro in
                        MacroProgress(
                            macro.name,
                            value: macro.value,
                            target: macro.target,
                            progress: macro.progress,
                            systemImage: macro.systemImage
                        )
                        .registryTint(macro.tint)

                        if macro.id != macros.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(theme.metrics.standardSpacing)
                .registrySurface()
            }

            Button(action: onLogFood) {
                Label(actionTitle, systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .registryItem("nutrition-overview")
    }
}

private struct NutritionOverviewPreview: View {
    var body: some View {
        ScrollView {
            NutritionOverview(
                "Today",
                energyTitle: "Energy",
                energy: Text("1,640 kcal"),
                energyDetail: Text("360 kcal remaining"),
                sectionTitle: "Macronutrients",
                macros: [
                    NutritionMacroItem(
                        id: "protein",
                        name: "Protein",
                        value: Text("96 g"),
                        target: Text("130 g"),
                        progress: 96.0 / 130.0,
                        systemImage: "fish.fill",
                        tint: .indigo
                    ),
                    NutritionMacroItem(
                        id: "carbs",
                        name: "Carbohydrates",
                        value: Text("182 g"),
                        target: Text("240 g"),
                        progress: 182.0 / 240.0,
                        systemImage: "leaf.fill",
                        tint: .green
                    ),
                    NutritionMacroItem(
                        id: "fat",
                        name: "Fat",
                        value: Text("48 g"),
                        target: Text("65 g"),
                        progress: 48.0 / 65.0,
                        systemImage: "drop.fill",
                        tint: .orange
                    )
                ],
                actionTitle: "Log food",
                onLogFood: {}
            )
            .padding()
        }
    }
}

#Preview("Nutrition Overview") {
    NutritionOverviewPreview()
}

#Preview("Nutrition Overview Dark") {
    NutritionOverviewPreview().preferredColorScheme(.dark)
}

#Preview("Nutrition Overview Accessibility Size") {
    NutritionOverviewPreview().dynamicTypeSize(.accessibility3)
}
