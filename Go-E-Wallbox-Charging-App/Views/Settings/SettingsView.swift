import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    private enum Field { case ip, batterySize, chargingFactor }
    @FocusState private var focusedField: Field?

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(AppConstants.UI.settingsSectionConnection)) {
                    LabeledContent(AppConstants.UI.wallboxIP) {
                        TextField("192.168.x.x", text: $viewModel.chargerIP)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .ip)
                    }
                }

                Section(
                    header: Text(AppConstants.UI.settingsSectionBattery),
                    footer: Text(AppConstants.UI.batterySizeFooter)
                ) {
                    LabeledContent(AppConstants.UI.batterySizeKWh) {
                        HStack {
                            TextField("42", value: $viewModel.batterySizeKWh, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .batterySize)
                            Text(AppConstants.UI.unitKWh)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(
                    header: Text(AppConstants.UI.settingsSectionCharging),
                    footer: Text(AppConstants.UI.chargingEnergyFactorFooter)
                ) {
                    LabeledContent(AppConstants.UI.chargingEnergyFactor) {
                        TextField("0.85", value: $viewModel.chargingEnergyFactor, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .chargingFactor)
                    }
                }

                Section(
                    header: Text(AppConstants.UI.settingsSectionRFID),
                    footer: Text(AppConstants.UI.settingsRFIDHint)
                ) {
                    if viewModel.availableCards.isEmpty {
                        Text(AppConstants.UI.settingsRFIDNoCards)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker(AppConstants.UI.settingsRFIDUser, selection: $viewModel.selectedCardIndex) {
                            ForEach(viewModel.availableCards) { card in
                                Text(card.name).tag(card.id)
                            }
                        }
                    }
                }

            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(AppConstants.UI.settingsTitle)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(AppConstants.UI.done) {
                        focusedField = nil
                    }
                }
            }
        }
    }
}
