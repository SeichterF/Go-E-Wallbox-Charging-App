import Foundation
import Observation

@Observable
@MainActor
final class DashboardViewModel {
    private let service: WallboxServiceProtocol

    var isLoading = false
    var errorMessage: String?
    var status: WallboxStatus = .placeholder

    init(service: WallboxServiceProtocol) {
        self.service = service
    }

    func refreshStatus() async {
        isLoading = true
        errorMessage = nil

        do {
            status = try await service.fetchStatus()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
