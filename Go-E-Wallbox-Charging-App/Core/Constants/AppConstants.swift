import Foundation

enum AppConstants {
    enum UI {
        static let dashboardTitle = "Dashboard"
        static let settingsTitle = "Settings"
        static let refresh = "Refresh"
        static let save = "Save"
        static let wallboxIP = "Wallbox IP"
        static let batterySizeKWh = "Battery Size (kWh)"
        static let targetSOCFormat = "Target SOC: %d%%"
        static let lossFactor = "Loss Factor"
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
    }
}
