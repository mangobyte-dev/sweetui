import SwiftUI
import SweetUIFoundations

/// A shipping address form, translated from shadcn's shipping-address: street
/// and apartment fields, city and state and zip and country paired two-up, a
/// save-as-default checkbox, and cancel and save actions. The text fields wear
/// the registry input treatment, the state and country pickers the registry
/// select, and the checkbox the registry checkbox toggle style.
public struct ShippingAddress: View {
    @Environment(\.registryTheme) private var theme
    @State private var street = "123 Main Street"
    @State private var apartment = "Apt 4B"
    @State private var city = "San Francisco"
    @State private var state = "CA"
    @State private var zip = "94102"
    @State private var country = "US"
    @State private var saveAsDefault = true

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Where should we deliver?")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                FieldGroup {
                    Field("Street address") { _ in
                        TextField("123 Main Street", text: $street)
                            .textFieldStyle(.registryInput)
                            .accessibilityLabel("Street address")
                    }

                    Field("Apt / Suite") { _ in
                        TextField("Apt 4B", text: $apartment)
                            .textFieldStyle(.registryInput)
                            .accessibilityLabel("Apt or suite")
                    }

                    HStack(alignment: .top, spacing: theme.metrics.standardSpacing) {
                        Field("City") { _ in
                            TextField("San Francisco", text: $city)
                                .textFieldStyle(.registryInput)
                                .accessibilityLabel("City")
                        }

                        Field("State") { _ in
                            Picker("State", selection: $state) {
                                Text("California").tag("CA")
                                Text("New York").tag("NY")
                                Text("Texas").tag("TX")
                            }
                            .registrySelect()
                            .accessibilityLabel("State")
                        }
                    }

                    HStack(alignment: .top, spacing: theme.metrics.standardSpacing) {
                        Field("ZIP Code") { _ in
                            TextField("94102", text: $zip)
                                .textFieldStyle(.registryInput)
                                .accessibilityLabel("ZIP code")
                        }

                        Field("Country") { _ in
                            Picker("Country", selection: $country) {
                                Text("United States").tag("US")
                                Text("Canada").tag("CA")
                                Text("United Kingdom").tag("UK")
                            }
                            .registrySelect()
                            .accessibilityLabel("Country")
                        }
                    }

                    Toggle(isOn: $saveAsDefault) {
                        Text("Save as default address")
                    }
                    .toggleStyle(.registryCheckbox)
                }

                HStack(spacing: theme.metrics.compactSpacing) {
                    Button("Cancel") {}
                        .buttonStyle(.registryOutline)
                        .controlSize(.small)
                    Spacer()
                    Button("Save Address") {}
                        .buttonStyle(.registry)
                        .controlSize(.small)
                }
            }
        } label: {
            Text("Shipping Address")
        }
        .groupBoxStyle(.registryCard)
    }
}

#if DEBUG
#Preview("Shipping Address") {
    ScrollView { ShippingAddress().padding() }
        .registryTheme(.indigo)
}

#Preview("Shipping Address Dark") {
    ScrollView { ShippingAddress().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
