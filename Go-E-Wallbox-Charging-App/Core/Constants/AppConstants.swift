import Foundation

enum AppConstants {
    enum UI {
        static let dashboardTitle = String(localized: "dashboard_title")
        static let settingsTitle = String(localized: "settings_title")
        static let save = String(localized: "save")
        static let done = String(localized: "done")
        // Settings – section headers
        static let settingsSectionConnection = String(localized: "settings_section_connection")
        static let settingsSectionBattery = String(localized: "settings_section_battery")
        static let settingsSectionCharging = String(localized: "settings_section_charging")

        // Settings – field labels
        static let wallboxIP = String(localized: "wallbox_ip")
        static let batterySizeKWh = String(localized: "battery_size_kwh")
        static let chargingEnergyFactor = String(localized: "charging_energy_factor")

        // Settings – units
        static let unitKWh = String(localized: "unit_kwh")
        static let unitPercent = String(localized: "unit_percent")

        // Settings – footer descriptions
        static let batterySizeFooter = String(localized: "battery_size_footer")
        static let chargingEnergyFactorFooter = String(localized: "charging_energy_factor_footer")

        // Dashboard – section headers
        static let dashboardSectionStatus = String(localized: "dashboard_section_status")
        static let dashboardSectionChargeLimit = String(localized: "dashboard_section_charge_limit")

        // Dashboard – field labels
        static let dashboardStatusLabel = String(localized: "dashboard_status_label")
        static let dashboardChargingPowerLabel = String(localized: "dashboard_charging_power_label")
        static let dashboardEnergyTodayLabel = String(localized: "dashboard_energy_today_label")
        static let dashboardEnergyLimitLabel = String(localized: "dashboard_energy_limit_label")

        // Dashboard – units
        static let unitKW = String(localized: "unit_kw")

        // Dashboard – formatted values
        static let dashboardEnergyLimitValueFormat = String(localized: "dashboard_energy_limit_value_format")

        static let statusDisconnected = String(localized: "status_disconnected")
        static let statusCharging = String(localized: "status_charging")
        static let statusWaiting = String(localized: "status_waiting")
        static let statusComplete = String(localized: "status_complete")
        static let statusUnknown = String(localized: "status_unknown")
        static let loading = String(localized: "loading")
        static let currentSOCFieldLabel = String(localized: "current_soc_field_label")
        static let currentSOCPercentSuffix = String(localized: "unit_percent")
        static let currentSOCTextFieldPlaceholder = String(localized: "current_soc_placeholder")
        static let estimatedCurrentSOCLabel = String(localized: "estimated_current_soc_label")
        static let calculatedChargeLimitLabel = String(localized: "calculated_charge_limit_label")
        static let calculatedChargeLimitValueFormat = String(localized: "calculated_charge_limit_value_format")
        static let calculatedChargeLimitTargetReached = String(localized: "calculated_charge_limit_target_reached")
        static let calculatedChargeLimitFormat = String(localized: "calculated_charge_limit_format")
        static let calculatedChargeLimitNone = String(localized: "calculated_charge_limit_none")
        static let noChargeLimitValue = String(localized: "no_charge_limit_value")

        // SOC Progress Bar labels
        static let socProgressCurrentLabel = String(localized: "soc_progress_current_label")
        static let socProgressAfterTodayLabel = String(localized: "soc_progress_after_today_label")
        static let socProgressTargetLabel = String(localized: "soc_progress_target_label")

        // SOC input validation
        static let socValidationErrorMax = String(localized: "soc_validation_error_max")
        static let targetSOCValidationErrorRange = String(localized: "target_soc_validation_error_range")

        // Settings – RFID section
        static let settingsSectionRFID = String(localized: "settings_section_rfid")
        static let settingsRFIDUser = String(localized: "settings_rfid_user")
        static let settingsRFIDNoCards = String(localized: "settings_rfid_no_cards")
        static let settingsRFIDHint = String(localized: "settings_rfid_hint")

        // Dashboard – charging control
        static let dashboardStartCharging = String(localized: "dashboard_start_charging")
        static let dashboardStopCharging = String(localized: "dashboard_stop_charging")
        static let dashboardChargingAsFormat = String(localized: "dashboard_charging_as_format")
    }
}
