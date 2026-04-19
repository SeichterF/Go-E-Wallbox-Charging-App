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
                    Text(String(format: AppConstants.UI.targetSOCFormat, viewModel.targetSOCPercent))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(AppConstants.UI.currentSOCFieldLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

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

                    Text(String(format: AppConstants.UI.currentSOCFormat, viewModel.parsedCurrentSOCPercent))
                        .font(.body)

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
