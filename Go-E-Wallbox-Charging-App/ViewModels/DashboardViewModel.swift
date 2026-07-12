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
    /// True while the field is empty because the user just tapped in to overwrite.
    var socFieldIsCleared = false

    /// Transient current SOC while the user drags the current dot; nil = not dragging.
    var currentSOCDragValue: Int?

    /// Transient target while the user drags the knob; settings are written on commit only.
    var targetSOCDragValue: Int?
    /// Digits-only display for the target SOC while editing via keyboard.
    var targetSOCText: String = ""
    /// True while the target field is empty because the user just tapped in to overwrite.
    var targetSOCFieldIsCleared = false

    private var socTextBeforeEditing = "0"
    private var wallboxSyncTask: Task<Void, Never>?
    private var lastSyncedSOC: Int?
    private var lastSyncedLimitWh: Int?
    private var needsInitializationFromWallbox = true

    init(service: WallboxServiceProtocol, settings: AppSettings) {
        self.service = service
        self.settings = settings
        self.targetSOCText = String(settings.targetSOCPercent)
    }

    /// Current SOC shown on the progress bar: live drag value while dragging, otherwise parsed text.
    var displayedCurrentSOCPercent: Int {
        currentSOCDragValue ?? parsedCurrentSOCPercent
    }

    /// Target SOC shown in the UI: the live drag value while dragging, otherwise the persisted setting.
    var displayedTargetSOCPercent: Int {
        targetSOCDragValue ?? settings.targetSOCPercent
    }

    var socValidationError: String? {
        let digits = currentSOCText.filter(\.isNumber)
        guard !digits.isEmpty, let value = Int(digits) else { return nil }
        return value > 100 ? AppConstants.UI.socValidationErrorMax : nil
    }

    var parsedCurrentSOCPercent: Int {
        let digits = currentSOCText.filter(\.isNumber)
        guard !digits.isEmpty else { return 0 }
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
        needsInitializationFromWallbox = true
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

    var isForceCharging: Bool {
        status.connectionState == .charging || status.forceState == 2
    }

    var canStartCharging: Bool {
        status.isConnected && !isForceCharging
    }

    var selectedCardName: String? {
        settings.availableCards.first(where: { $0.id == settings.selectedCardIndex })?.name
    }

    func startCharging() async {
        isLoading = true
        errorMessage = nil
        let cardIndex = settings.availableCards.isEmpty ? -1 : settings.selectedCardIndex
        do {
            try await service.startCharging(cardIndex: cardIndex)
            status = try await service.fetchStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func stopCharging() async {
        isLoading = true
        errorMessage = nil
        do {
            try await service.stopCharging()
            status = try await service.fetchStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func refreshStatus() async {
        isLoading = true
        errorMessage = nil

        do {
            status = try await service.fetchStatus()
            settings.availableCards = status.availableCards
            if needsInitializationFromWallbox {
                initializeSOCFromWallbox()
                needsInitializationFromWallbox = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func beginEditing() {
        socTextBeforeEditing = currentSOCText
        currentSOCText = ""
        socFieldIsCleared = true
    }

    func endEditing() {
        if currentSOCText.isEmpty {
            currentSOCText = socTextBeforeEditing
        }
        socFieldIsCleared = false
    }

    /// Strips non-digits, stores raw value (no clamping), and syncs only when valid.
    func replaceCurrentSOCTextWithSanitizedUserInput(_ raw: String) {
        let digits = raw.filter(\.isNumber)
        currentSOCText = digits.isEmpty ? "" : String(Int(digits) ?? 0)
        socFieldIsCleared = currentSOCText.isEmpty

        if !currentSOCText.isEmpty && socValidationError == nil {
            scheduleDebouncedWallboxSync()
        }
    }

    // MARK: - Current SOC drag

    func updateCurrentSOCDrag(fraction: Double) {
        let step = Double(settings.socStepPercent)
        let snapped = Int((fraction * 100.0 / step).rounded() * step)
        let clamped = min(100, max(0, snapped))
        currentSOCDragValue = clamped
        currentSOCText = String(clamped)
        socFieldIsCleared = false
    }

    func commitCurrentSOCDrag() {
        guard let value = currentSOCDragValue else { return }
        currentSOCDragValue = nil
        currentSOCText = String(value)
        if socValidationError == nil {
            scheduleDebouncedWallboxSync()
        }
    }

    // MARK: - Target SOC

    var targetSOCValidationError: String? {
        let digits = targetSOCText.filter(\.isNumber)
        guard !digits.isEmpty, let value = Int(digits) else { return nil }
        guard !(settings.minSOCPercent...settings.maxSOCPercent).contains(value) else { return nil }
        return String(
            format: AppConstants.UI.targetSOCValidationErrorRange,
            settings.minSOCPercent,
            settings.maxSOCPercent
        )
    }

    /// Maps a horizontal position on the progress bar (0…1) to a target SOC,
    /// snapped to `socStepPercent` and clamped to the allowed range.
    func updateTargetSOCDrag(fraction: Double) {
        let step = Double(settings.socStepPercent)
        let snapped = Int((fraction * 100.0 / step).rounded() * step)
        targetSOCDragValue = min(settings.maxSOCPercent, max(settings.minSOCPercent, snapped))
    }

    func commitTargetSOCDrag() {
        guard let value = targetSOCDragValue else { return }
        targetSOCDragValue = nil
        applyTargetSOC(value)
    }

    func beginEditingTargetSOC() {
        targetSOCText = ""
        targetSOCFieldIsCleared = true
    }

    func endEditingTargetSOC() {
        targetSOCText = String(settings.targetSOCPercent)
        targetSOCFieldIsCleared = false
    }

    /// Strips non-digits and applies the value to settings only while it is within range.
    func replaceTargetSOCTextWithSanitizedUserInput(_ raw: String) {
        let digits = raw.filter(\.isNumber)
        targetSOCText = digits.isEmpty ? "" : String(Int(digits) ?? 0)
        targetSOCFieldIsCleared = targetSOCText.isEmpty

        guard let value = Int(targetSOCText),
              (settings.minSOCPercent...settings.maxSOCPercent).contains(value) else { return }
        applyTargetSOC(value)
    }

    private func applyTargetSOC(_ value: Int) {
        settings.targetSOCPercent = value
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

    private func initializeSOCFromWallbox() {
        let limitWh = status.chargeLimitWh
        guard limitWh > 0,
              settings.batterySizeKWh > 0,
              settings.chargingEnergyFactor > 0 else { return }

        let implied = settings.targetSOCPercent
            - Int((Double(limitWh) * 100.0
                / (settings.batterySizeKWh * 1000.0 * settings.chargingEnergyFactor)).rounded())
        let clamped = max(0, min(100, implied))
        currentSOCText = String(clamped)
        lastSyncedSOC = clamped
        lastSyncedLimitWh = limitWh
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
