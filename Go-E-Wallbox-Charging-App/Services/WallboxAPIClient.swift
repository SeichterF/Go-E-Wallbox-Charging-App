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
        let chargingPowerW = powerWFromNRG.safeRoundedInt ?? 0
        let sessionEnergyWh = intValue(from: jsonObject["wh"]) ?? 0
        let chargeLimitWh = intValue(from: jsonObject["dwo"]) ?? 0
        let forceState = intValue(from: jsonObject["frc"]) ?? 0
        let activeTransaction = intValue(from: jsonObject["trx"]) ?? -1
        let availableCards = parseCards(jsonObject["cards"])

        return WallboxStatus(
            isConnected: [.charging, .waiting, .complete].contains(connectionState),
            connectionState: connectionState,
            chargingPowerW: chargingPowerW,
            energyPerDayWh: sessionEnergyWh,
            chargeLimitWh: chargeLimitWh,
            forceState: forceState,
            activeTransaction: activeTransaction,
            availableCards: availableCards
        )
    }

    func setChargeEnergyLimitWh(_ dwoWh: Int) async throws {
        try await setParameter(name: "dwo", value: String(dwoWh))
    }

    func setForceState(_ value: Int) async throws {
        try await setParameter(name: "frc", value: String(value))
    }

    func setTransaction(_ index: Int) async throws {
        try await setParameter(name: "trx", value: String(index))
    }

    private func setParameter(name: String, value: String) async throws {
        guard var components = URLComponents(string: "\(settings.apiBaseURLString)set") else {
            throw URLError(.badURL)
        }

        components.queryItems = [URLQueryItem(name: name, value: value)]

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

    private func parseCards(_ cardsValue: Any?) -> [RFIDCard] {
        guard let cardsArray = cardsValue as? [Any] else { return [] }
        return cardsArray.enumerated().compactMap { index, item -> RFIDCard? in
            guard let card = item as? [String: Any],
                  let name = card["name"] as? String else {
                return nil
            }
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, trimmed.caseInsensitiveCompare("N/A") != .orderedSame else {
                return nil
            }
            return RFIDCard(id: index, name: trimmed)
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
            // A malformed response must not trap on NaN/infinity — treat it as "missing".
            return doubleValue.safeRoundedInt
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
