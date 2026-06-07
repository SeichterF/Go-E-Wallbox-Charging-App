import Foundation

struct WallboxAPIClient {
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    func fetchStatus() async throws -> WallboxStatus {
        guard let statusURL = URL(string: "\(settings.apiBaseURLString)status") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: statusURL)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        let carStatusValue = intValue(from: jsonObject["car"]) ?? 0
        let powerWFromNRG = powerFromEnergyArray(jsonObject["nrg"])
        let chargingPowerW = Int(powerWFromNRG.rounded())
        let sessionEnergyWh = intValue(from: jsonObject["wh"]) ?? 0
        let chargeLimitWh = intValue(from: jsonObject["dwo"]) ?? 0

        return WallboxStatus(
            isConnected: carStatusValue != 0,
            connectionState: mapConnectionState(from: carStatusValue),
            chargingPowerW: chargingPowerW,
            energyPerDayWh: sessionEnergyWh,
            chargeLimitWh: chargeLimitWh
        )
    }

    func setChargeEnergyLimitWh(_ dwoWh: Int) async throws {
        guard var components = URLComponents(string: "\(settings.apiBaseURLString)set") else {
            throw URLError(.badURL)
        }

        components.queryItems = [URLQueryItem(name: "dwo", value: String(dwoWh))]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (_, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }

    private func mapConnectionState(from carValue: Int) -> WallboxStatus.ConnectionState {
        switch carValue {
        case 0:
            return .disconnected
        case 1:
            return .idle
        case 2:
            return .charging
        case 3:
            return .waiting
        case 4:
            return .complete
        default:
            return .unknown
        }
    }

    private func powerFromEnergyArray(_ nrgValue: Any?) -> Double { // nrg[11] is total power in W
        guard let nrgArray = nrgValue as? [Any], nrgArray.count > 11 else {
            return 0
        }

        return doubleValue(from: nrgArray[11]) ?? 0
    }

    private func intValue(from rawValue: Any?) -> Int? {
        if let intValue = rawValue as? Int {
            return intValue
        }
        if let stringValue = rawValue as? String {
            return Int(stringValue)
        }
        if let doubleValue = rawValue as? Double {
            return Int(doubleValue.rounded())
        }

        return nil
    }

    private func doubleValue(from rawValue: Any?) -> Double? {
        if let doubleValue = rawValue as? Double {
            return doubleValue
        }
        if let intValue = rawValue as? Int {
            return Double(intValue)
        }
        if let stringValue = rawValue as? String {
            return Double(stringValue)
        }

        return nil
    }
}
