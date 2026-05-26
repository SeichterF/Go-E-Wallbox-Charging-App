import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: DashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statusCard
                    chargeLimitCard
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(AppConstants.UI.dashboardTitle)
            .task(id: scenePhase == .active) {
                guard scenePhase == .active else { return }
                await viewModel.startPolling()
            }
        }
    }

    // MARK: - Cards

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: viewModel.status.connectionState.iconName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(viewModel.status.connectionState.tintColor)
                Text(viewModel.status.connectionStateLabel)
                    .font(.headline)
                    .foregroundStyle(viewModel.status.connectionState.tintColor)
                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text(AppConstants.UI.dashboardChargingPowerLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(viewModel.status.chargingPowerW)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text(AppConstants.UI.unitWatt)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(AppConstants.UI.dashboardEnergyTodayLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(viewModel.status.energyPerDayWh)")
                            .font(.title3.weight(.semibold))
                        Text(AppConstants.UI.unitWh)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(AppConstants.UI.dashboardEnergyLimitLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if viewModel.status.chargeLimitWh > 0 {
                        Text(String(
                            format: AppConstants.UI.dashboardEnergyLimitValueFormat,
                            Double(viewModel.status.chargeLimitWh) / 1000.0
                        ))
                        .font(.title3.weight(.semibold))
                    } else {
                        Text(AppConstants.UI.noChargeLimitValue)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var chargeLimitCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(AppConstants.UI.dashboardSectionChargeLimit)
                .font(.headline)
                .padding(.bottom, 16)

            Divider()

            cardRow(label: AppConstants.UI.targetBatteryLevel) {
                Text("\(viewModel.targetSOCPercent) \(AppConstants.UI.unitPercent)")
                    .font(.body.weight(.medium))
            }

            Divider()

            cardRow(label: AppConstants.UI.currentSOCFieldLabel) {
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

            Divider()

            cardRow(label: AppConstants.UI.calculatedChargeLimitLabel) {
                if viewModel.previewChargeLimitWh > 0 {
                    Text(String(
                        format: AppConstants.UI.calculatedChargeLimitValueFormat,
                        Double(viewModel.previewChargeLimitWh) / 1000.0
                    ))
                    .font(.body.weight(.medium))
                } else {
                    Text(AppConstants.UI.calculatedChargeLimitTargetReached)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private func cardRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            content()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - ConnectionState view helpers

private extension WallboxStatus.ConnectionState {
    var tintColor: Color {
        switch self {
        case .disconnected, .unknown: return .secondary
        case .idle: return .orange
        case .charging: return .green
        case .waiting: return .yellow
        case .complete: return .blue
        }
    }

    var iconName: String {
        switch self {
        case .disconnected: return "bolt.slash.fill"
        case .idle: return "bolt.fill"
        case .charging: return "bolt.car.fill"
        case .waiting: return "clock.fill"
        case .complete: return "checkmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
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
