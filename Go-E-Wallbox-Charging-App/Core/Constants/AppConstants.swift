import Foundation

enum AppConstants {
    enum UI {
        static let dashboardTitle = "Dashboard"
        static let settingsTitle = "Settings"
        static let refresh = "Refresh"
        static let save = "Save"
        // Settings – section headers
        static let settingsSectionConnection = "Connection"
        static let settingsSectionBattery = "Battery"
        static let settingsSectionCharging = "Charging"

        // Settings – field labels
        static let wallboxIP = "Wallbox IP"
        static let batterySizeKWh = "Battery Size"
        static let targetSOCFormat = "Target SOC: %d %%"
        static let chargingEnergyFactor = "Energy Factor"

        // Settings – units
        static let unitKWh = "kWh"
        static let unitPercent = "%"

        // Settings – footer descriptions
        static let batterySizeFooter = "Total usable capacity of your EV battery."
        static let chargingEnergyFactorFooter = "Accounts for charging losses. 0.85 means the car requires ~18 % more energy than its net SOC gain."
        static let wallboxStatusFormat = "Wallbox Status: %@"
        static let chargingPowerFormat = "Charging Power: %d W"
        static let energyTodayFormat = "Energy Today: %d Wh"
        static let connected = "Connected"
        static let disconnected = "Disconnected"
        static let statusDisconnected = "Disconnected"
        static let statusIdle = "Plugged In (Idle)"
        static let statusCharging = "Charging"
        static let statusWaiting = "Waiting"
        static let statusComplete = "Charge Complete"
        static let statusUnknown = "Unknown"
        static let loading = "Loading..."
        static let currentSOCFieldLabel = "Current SOC"
        static let currentSOCPercentSuffix = "%"
        static let currentSOCTextFieldPlaceholder = "0"
        static let calculatedChargeLimitFormat = "Calculated limit: %.1f kWh (%d Wh)"
        static let calculatedChargeLimitNone = "Calculated limit: none (unlimited on wallbox)"
        static let noChargeLimit = "Energy limit: none (unlimited)"
        static let energyLimitWhFormat = "Energy limit: %.1f kWh (%d Wh)"
    }
}
