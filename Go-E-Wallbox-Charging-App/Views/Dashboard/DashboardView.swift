import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            VStack(spacing: 16) {
                StatusBadge(isConnected: viewModel.status.isConnected)
                ChargingCardView(status: viewModel.status)

                VStack(alignment: .leading, spacing: 12) {
                    Text("\(AppConstants.UI.targetBatteryLevel): \(viewModel.targetSOCPercent) \(AppConstants.UI.unitPercent)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .center, spacing: 12) {
                        Text(AppConstants.UI.currentSOCFieldLabel)
                            .font(.body)

                        Spacer(minLength: 8)

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
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.secondary.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(.secondary.opacity(0.35), lineWidth: 1)
                        )
                    }

                    if viewModel.previewChargeLimitWh > 0 {
                        Text(
                            String(
                                format: AppConstants.UI.calculatedChargeLimitFormat,
                                Double(viewModel.previewChargeLimitWh) / 1000.0,
                                viewModel.previewChargeLimitWh
                            )
                        )
                        .font(.subheadline)
                    } else {
                        Text(AppConstants.UI.calculatedChargeLimitNone)
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                PrimaryButton(title: AppConstants.UI.refresh) {
                    Task {
                        await viewModel.refreshStatus()
                    }
                }
                .disabled(viewModel.isLoading)
            }
            .padding()
            .navigationTitle(AppConstants.UI.dashboardTitle)
            .task {
                await viewModel.refreshStatus()
            }
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
