import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                StatusBadge(isConnected: viewModel.status.isConnected)
                ChargingCardView(status: viewModel.status)

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
        }
    }
}

#Preview {
    DashboardView(
        viewModel: DashboardViewModel(
            service: WallboxService(
                apiClient: WallboxAPIClient(settings: AppSettings()),
                settings: AppSettings()
            )
        )
    )
}
