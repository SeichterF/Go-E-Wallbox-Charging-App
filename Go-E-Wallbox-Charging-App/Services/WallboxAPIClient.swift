import Foundation

struct WallboxAPIClient {
    private let settings: AppSettings
    private let session: URLSession

    init(settings: AppSettings, session: URLSession = .shared) {
        self.settings = settings
        self.session = session
    }

    func fetchStatus() async throws -> WallboxStatus {
        guard let statusURL = URL(string: "\(settings.apiBaseURLString)status") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await session.data(from: statusURL)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        let carStatusValue = intValue(from: jsonObject["car"]) ?? 0
        let connectionState = mapConnectionState(from: carStatusValue)
        let powerWFromNRG = powerFromEnergyArray(jsonObject["nrg"])
        let chargingPowerW = Int(powerWFromNRG.rounded())
        let sessionEnergyWh = intValue(from: jsonObject["wh"]) ?? 0
        let chargeLimitWh = intValue(from: jsonObject["dwo"]) ?? 0

        return WallboxStatus(
            isConnected: [.charging, .waiting, .complete].contains(connectionState),
            connectionState: connectionState,
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

        let (_, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }

    // go-e API v2 `car` enum: Unknown/Error=0, Idle=1 (no vehicle connected),
    // Charging=2, WaitCar=3, Complete=4, Error=5, Initializing=6
    private func mapConnectionState(from carValue: Int) -> WallboxStatus.ConnectionState {
        switch carValue {
        case 1:
            return .disconnected
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
