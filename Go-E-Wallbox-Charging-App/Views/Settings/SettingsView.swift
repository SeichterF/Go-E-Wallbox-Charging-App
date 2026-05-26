import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

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
                            Text(AppConstants.UI.unitKWh)
                                .foregroundStyle(.secondary)
                        }
                    }

                    LabeledContent(AppConstants.UI.targetBatteryLevel) {
                        HStack {
                            TextField("80", value: $viewModel.targetSOCPercent, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                            Text(AppConstants.UI.unitPercent)
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
                    }
                }

                PrimaryButton(title: AppConstants.UI.save) {
                    Task {
                        await viewModel.save()
                    }
                }
                .disabled(viewModel.isLoading)
            }
            .navigationTitle(AppConstants.UI.settingsTitle)
        }
    }
}
