import Foundation
import Observation

@Observable
@MainActor
final class DashboardViewModel {
    private let service: WallboxServiceProtocol
    private let settings: AppSettings

    private static let wallboxSyncDebounceNanoseconds: UInt64 = 450_000_000

    var isLoading = false
    var errorMessage: String?
    var status: WallboxStatus = .placeholder

    /// Digits-only display for current SOC; default `"0"` (0%).
    var currentSOCText: String = "0"

    private var wallboxSyncTask: Task<Void, Never>?
    private var lastSyncedSOC: Int?
    private var lastSyncedLimitWh: Int?

    init(service: WallboxServiceProtocol, settings: AppSettings) {
        self.service = service
        self.settings = settings
    }

    var targetSOCPercent: Int {
        settings.targetSOCPercent
    }

    var parsedCurrentSOCPercent: Int {
        let digits = currentSOCText.filter(\.isNumber)
        guard !digits.isEmpty else {
            return 0
        }
        return min(100, Int(digits) ?? 0)
    }

    var chargingSettingsForApply: ChargingSettings {
        ChargingSettings(
            currentSOCPercent: parsedCurrentSOCPercent,
            targetSOCPercent: settings.targetSOCPercent,
            batterySizeKWh: settings.batterySizeKWh,
            chargingEnergyFactor: settings.chargingEnergyFactor
        )
    }

    var previewChargeLimitWh: Int {
        chargingSettingsForApply.computedChargeLimitWh
    }

    var calculatedCurrentSOCPercent: Int {
        guard settings.batterySizeKWh > 0 else { return parsedCurrentSOCPercent }
        let chargedKWh = Double(status.energyPerDayWh) / 1000.0
        let storedKWh = chargedKWh * settings.chargingEnergyFactor
        let socGain = storedKWh / settings.batterySizeKWh * 100.0
        return min(100, parsedCurrentSOCPercent + Int(socGain.rounded()))
    }

    func startPolling() async {
        while !Task.isCancelled {
            await refreshStatus()
            guard !Task.isCancelled else { break }
            do {
                try await Task.sleep(for: .seconds(settings.pollingIntervalSeconds))
            } catch {
                break
            }
        }
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

    /// Sanitizes to digits only, clamps to 0…100, then schedules a debounced wallbox sync.
    func replaceCurrentSOCTextWithSanitizedUserInput(_ raw: String) {
        let digits = raw.filter(\.isNumber)
        if digits.isEmpty {
            currentSOCText = "0"
        } else if let value = Int(digits) {
            currentSOCText = String(min(100, value))
        } else {
            currentSOCText = "0"
        }

        scheduleDebouncedWallboxSync()
    }

    func scheduleDebouncedWallboxSync() {
        wallboxSyncTask?.cancel()
        wallboxSyncTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: Self.wallboxSyncDebounceNanoseconds)
            } catch {
                return
            }

            guard !Task.isCancelled else {
                return
            }

            await synchronizeChargeLimitWithWallbox()
        }
    }

    func synchronizeChargeLimitWithWallbox() async {
        let soc = parsedCurrentSOCPercent
        let limit = chargingSettingsForApply.computedChargeLimitWh
        if lastSyncedSOC == soc, lastSyncedLimitWh == limit {
            return
        }

        errorMessage = nil

        do {
            try await service.updateChargingSettings(chargingSettingsForApply)
            status = try await service.fetchStatus()
            lastSyncedSOC = soc
            lastSyncedLimitWh = limit
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
