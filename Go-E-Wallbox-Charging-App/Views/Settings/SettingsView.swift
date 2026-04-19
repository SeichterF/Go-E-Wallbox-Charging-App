import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(AppConstants.UI.wallboxIP, text: $viewModel.chargerIP)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField(AppConstants.UI.batterySizeKWh, value: $viewModel.batterySizeKWh, format: .number)
                    .keyboardType(.decimalPad)

                Stepper(
                    value: $viewModel.targetSOCPercent,
                    in: viewModel.minSOCPercent...viewModel.maxSOCPercent,
                    step: viewModel.socStepPercent
                ) {
                    Text(String(format: AppConstants.UI.targetSOCFormat, viewModel.targetSOCPercent))
                }

                TextField(AppConstants.UI.chargingEnergyDivisor, value: $viewModel.chargingEnergyDivisor, format: .number)
                    .keyboardType(.decimalPad)

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
