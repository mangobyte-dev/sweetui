import SwiftUI

struct StageOneShowcase: View {
    @State private var name = "MangoByte"
    @State private var notes = "Native controls remain visible at every call site."
    @State private var accepted = true
    @State private var notifications = true
    @State private var bold = true
    @State private var italic = false
    @State private var plan = "pro"
    @State private var delivery = "standard"
    @State private var section = "controls"
    @State private var sort = "recent"
    @State private var volume = 0.64

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                Text("Stage 1 Components")
                    .font(.largeTitle.bold())

                GroupBox("Actions and status") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("Primary action") {}
                            .buttonStyle(.registry)

                        ControlGroup("Document actions") {
                            Button("Save", systemImage: "square.and.arrow.down") {}
                            Button("Share", systemImage: "square.and.arrow.up") {}
                        }
                        .labelStyle(.iconOnly)
                        .controlGroupStyle(.registryButtons)

                        Text("Ready")
                            .registryBadge(.positive)
                        Text("Needs attention")
                            .registryBadge(.destructive)
                    }
                }
                .groupBoxStyle(.registryCard)

                GroupBox("Text entry") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Name", text: $name)
                            .textFieldStyle(.registryInput)
                        TextEditor(text: $notes)
                            .registryTextArea(
                                accessibilityLabel: Text("Notes"),
                                minimumHeight: 88
                            )
                    }
                }
                .groupBoxStyle(.registryCard)

                GroupBox("Boolean controls") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Accept terms", isOn: $accepted)
                            .toggleStyle(.registryCheckbox)
                        Toggle("Notifications", isOn: $notifications)
                            .toggleStyle(.switch)
                        ControlGroup("Formatting") {
                            Toggle("Bold", systemImage: "bold", isOn: $bold)
                            Toggle("Italic", systemImage: "italic", isOn: $italic)
                        }
                        .labelStyle(.iconOnly)
                        .registryToggleGroup()
                    }
                }
                .groupBoxStyle(.registryCard)

                GroupBox("Selection") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Section", selection: $section) {
                            Text("Controls").tag("controls")
                            Text("Layout").tag("layout")
                        }
                        .pickerStyle(.segmented)

                        Picker("Plan", selection: $plan) {
                            Text("Basic").tag("basic")
                            Text("Pro").tag("pro")
                        }
                        .registrySelect()

                        Picker("Sort", selection: $sort) {
                            Text("Most recent").tag("recent")
                            Text("Oldest").tag("oldest")
                        }
                        .pickerStyle(.menu)

                        Picker("Delivery", selection: $delivery) {
                            Text("Standard").tag("standard")
                            Text("Express").tag("express")
                        }
                        .pickerStyle(.inline)
                    }
                }
                .groupBoxStyle(.registryCard)

                GroupBox("Progress and value") {
                    VStack(alignment: .leading, spacing: 16) {
                        ProgressView(value: 0.72) {
                            Text("Stage completion")
                        } currentValueLabel: {
                            Text("72 percent")
                        }
                        .progressViewStyle(.registryLinearPositive)

                        ProgressView("Checking registry")
                            .progressViewStyle(.registrySpinner)

                        HStack {
                            Label("Volume", systemImage: "speaker.wave.2.fill")
                                .labelStyle(.registry)
                            Spacer()
                            Text(volume, format: .percent.precision(.fractionLength(0)))
                                .monospacedDigit()
                        }
                        Slider(value: $volume) {
                            Text("Volume")
                        }
                    }
                }
                .groupBoxStyle(.registryCard)

                GroupBox("Native layout") {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider().registrySeparator()
                        Color.indigo
                            .overlay {
                                Image(systemName: "rectangle.inset.filled")
                                    .foregroundStyle(.white)
                                    .accessibilityHidden(true)
                            }
                            .aspectRatio(16.0 / 9.0, contentMode: .fit)
                            .accessibilityLabel("Sixteen by nine layout example")
                        Label("Leading content mirrors automatically", systemImage: "arrow.forward")
                            .labelStyle(.registry)
                    }
                }
                .groupBoxStyle(.registryCard)
            }
            .padding()
            .containerRelativeFrame(.horizontal) { length, _ in
                min(length, 792)
            }
        }
        .tint(.indigo)
    }
}

#Preview("Stage 1 Showcase") {
    StageOneShowcase()
}

#Preview("Stage 1 Showcase Dark RTL") {
    StageOneShowcase()
        .preferredColorScheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Stage 1 Showcase Accessibility Size") {
    StageOneShowcase()
        .dynamicTypeSize(.accessibility3)
}
