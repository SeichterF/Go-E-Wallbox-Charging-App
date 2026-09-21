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
                            TextField("42", text: Binding(
                                get: { viewModel.batterySizeText },
                                set: { viewModel.replaceBatterySizeTextWithSanitizedUserInput($0) }
                            ))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .batterySize)
                            Text(AppConstants.UI.unitKWh)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let error = viewModel.batterySizeValidationError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section(
                    header: Text(AppConstants.UI.settingsSectionCharging),
                    footer: Text(AppConstants.UI.chargingEnergyFactorFooter)
                ) {
                    LabeledContent(AppConstants.UI.chargingEnergyFactor) {
                        TextField("0.85", text: Binding(
                            get: { viewModel.chargingEnergyFactorText },
                            set: { viewModel.replaceChargingEnergyFactorTextWithSanitizedUserInput($0) }
                        ))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .chargingFactor)
                    }

                    if let error = viewModel.chargingEnergyFactorValidationError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: focusedField) { previousField, _ in
                switch previousField {
                case .batterySize:
                    viewModel.endEditingBatterySize()
                case .chargingFactor:
                    viewModel.endEditingChargingEnergyFactor()
                case .ip, .none:
                    break
                }
            }
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
