import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: DashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section(AppConstants.UI.dashboardSectionStatus) {
                    LabeledContent(AppConstants.UI.dashboardStatusLabel) {
                        StatusBadge(isConnected: viewModel.status.isConnected)
                    }
                    LabeledContent(
                        AppConstants.UI.dashboardChargingPowerLabel,
                        value: "\(viewModel.status.chargingPowerW) \(AppConstants.UI.unitWatt)"
                    )
                    LabeledContent(
                        AppConstants.UI.dashboardEnergyTodayLabel,
                        value: "\(viewModel.status.energyPerDayWh) \(AppConstants.UI.unitWh)"
                    )
                    if viewModel.status.chargeLimitWh > 0 {
                        LabeledContent(
                            AppConstants.UI.dashboardEnergyLimitLabel,
                            value: String(
                                format: AppConstants.UI.dashboardEnergyLimitValueFormat,
                                Double(viewModel.status.chargeLimitWh) / 1000.0
                            )
                        )
                    } else {
                        LabeledContent(
                            AppConstants.UI.dashboardEnergyLimitLabel,
                            value: AppConstants.UI.noChargeLimit
                        )
                    }
                }

                Section(
                    header: Text(AppConstants.UI.dashboardSectionChargeLimit),
                    footer: chargeLimitFooter
                ) {
                    LabeledContent(AppConstants.UI.targetBatteryLevel) {
                        Text("\(viewModel.targetSOCPercent) \(AppConstants.UI.unitPercent)")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent(AppConstants.UI.currentSOCFieldLabel) {
                        HStack(spacing: 4) {
                            TextField(
                                AppConstants.UI.currentSOCTextFieldPlaceholder,
                                text: Binding(
                                    get: { viewModel.currentSOCText },
                                    set: { viewModel.replaceCurrentSOCTextWithSanitizedUserInput($0) }
                                )
                            )
                            .keyboardType(.numberPad)
                            .textContentType(.none)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.trailing)
                            .frame(minWidth: 44, idealWidth: 56, maxWidth: 72)
                            Text(AppConstants.UI.currentSOCPercentSuffix)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(AppConstants.UI.dashboardTitle)
            .task(id: scenePhase == .active) {
                guard scenePhase == .active else { return }
                await viewModel.startPolling()
            }
        }
    }

    @ViewBuilder
    private var chargeLimitFooter: some View {
        if viewModel.previewChargeLimitWh > 0 {
            Text(
                String(
                    format: AppConstants.UI.calculatedChargeLimitFormat,
                    Double(viewModel.previewChargeLimitWh) / 1000.0,
                    viewModel.previewChargeLimitWh
                )
            )
        } else {
            Text(AppConstants.UI.calculatedChargeLimitNone)
        }
    }
}

#Preview {
    let settings = AppSettings()
    DashboardView(
        viewModel: DashboardViewModel(
            service: WallboxService(
                apiClient: WallboxAPIClient(settings: settings),
                settings: settings
            ),
            settings: settings
        )
    )
}
