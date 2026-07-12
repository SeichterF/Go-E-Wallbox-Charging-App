import Foundation
import Testing
@testable import Go_E_Wallbox_Charging_App

/// All tests that go through `URLProtocolStub` share its static state,
/// so this suite must run serialized.
@Suite(.serialized)
struct WallboxAPIClientTests {
    // MARK: - car state mapping

    @Test(arguments: [
        (0, WallboxStatus.ConnectionState.unknown, false),
        (1, WallboxStatus.ConnectionState.disconnected, false),
        (2, WallboxStatus.ConnectionState.charging, true),
        (3, WallboxStatus.ConnectionState.waiting, true),
        (4, WallboxStatus.ConnectionState.complete, true),
        (5, WallboxStatus.ConnectionState.unknown, false),
        (6, WallboxStatus.ConnectionState.unknown, false)
    ])
    func fetchStatusMapsCarValueToConnectionState(
        carValue: Int,
        expectedState: WallboxStatus.ConnectionState,
        expectedIsConnected: Bool
    ) async throws {
        let client = makeClient(json: #"{"car": \#(carValue)}"#)

        let status = try await client.fetchStatus()

        #expect(status.connectionState == expectedState)
        #expect(status.isConnected == expectedIsConnected)
    }

    @Test
    func fetchStatusWithoutCarFieldFallsBackToUnknown() async throws {
        let client = makeClient(json: #"{"wh": 100}"#)

        let status = try await client.fetchStatus()

        #expect(status.connectionState == .unknown)
        #expect(status.isConnected == false)
    }

    // MARK: - nrg power extraction

    @Test
    func fetchStatusReadsPowerFromNRGIndexElevenAndRounds() async throws {
        let client = makeClient(
            json: #"{"car": 2, "nrg": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7360.6]}"#
        )

        let status = try await client.fetchStatus()

        #expect(status.chargingPowerW == 7361)
    }

    @Test
    func fetchStatusWithShortOrMissingNRGArrayYieldsZeroPower() async throws {
        let shortArrayClient = makeClient(json: #"{"car": 2, "nrg": [1, 2, 3]}"#)
        #expect(try await shortArrayClient.fetchStatus().chargingPowerW == 0)

        let missingClient = makeClient(json: #"{"car": 2}"#)
        #expect(try await missingClient.fetchStatus().chargingPowerW == 0)
    }

    // MARK: - tolerant value parsing

    @Test
    func fetchStatusParsesStringAndDoubleEncodedFields() async throws {
        let client = makeClient(
            json: #"{"car": "2", "wh": 1234.6, "dwo": "15351"}"#
        )

        let status = try await client.fetchStatus()

        #expect(status.connectionState == .charging)
        #expect(status.energyPerDayWh == 1235)
        #expect(status.chargeLimitWh == 15351)
    }

    @Test
    func fetchStatusWithoutDwoFieldYieldsZeroChargeLimit() async throws {
        let client = makeClient(json: #"{"car": 2}"#)

        let status = try await client.fetchStatus()

        #expect(status.chargeLimitWh == 0)
    }

    @Test
    func fetchStatusRequestsStatusEndpointOnConfiguredHost() async throws {
        let client = makeClient(json: #"{"car": 1}"#)

        _ = try await client.fetchStatus()

        let requestedURL = try #require(URLProtocolStub.recordedURLs.last)
        #expect(requestedURL.absoluteString == "http://192.168.178.69/api/status")
    }

    // MARK: - error paths

    @Test(arguments: [404, 500])
    func fetchStatusThrowsOnNonSuccessStatusCode(statusCode: Int) async {
        let client = makeClient(json: #"{"car": 1}"#, statusCode: statusCode)

        await #expect(throws: URLError(.badServerResponse)) {
            _ = try await client.fetchStatus()
        }
    }

    @Test
    func fetchStatusThrowsWhenBodyIsNotAJSONObject() async {
        let client = makeClient(json: "[1, 2, 3]")

        await #expect(throws: URLError(.cannotParseResponse)) {
            _ = try await client.fetchStatus()
        }
    }

    // MARK: - setChargeEnergyLimitWh

    @Test
    func setChargeEnergyLimitSendsDwoAsQueryParameter() async throws {
        let client = makeClient(json: "{}")

        try await client.setChargeEnergyLimitWh(15351)

        let requestedURL = try #require(URLProtocolStub.recordedURLs.last)
        #expect(requestedURL.absoluteString == "http://192.168.178.69/api/set?dwo=15351")
    }

    @Test
    func setChargeEnergyLimitThrowsOnNonSuccessStatusCode() async {
        let client = makeClient(json: "{}", statusCode: 500)

        await #expect(throws: URLError(.badServerResponse)) {
            try await client.setChargeEnergyLimitWh(15351)
        }
    }

    // MARK: - WallboxService on top of the stubbed client

    @Test
    func serviceFetchStatusDelegatesToAPIClient() async throws {
        let settings = AppSettings()
        URLProtocolStub.setStub(statusCode: 200, body: Data(#"{"car": 2, "dwo": 15351}"#.utf8))
        let service = WallboxService(
            apiClient: WallboxAPIClient(settings: settings, session: URLProtocolStub.makeSession()),
            settings: settings
        )

        let status = try await service.fetchStatus()

        #expect(status.connectionState == .charging)
        #expect(status.chargeLimitWh == 15351)
    }

    @Test
    func serviceUpdateChargingSettingsSendsComputedLimitAsDwo() async throws {
        let settings = AppSettings()
        URLProtocolStub.setStub(statusCode: 200, body: Data("{}".utf8))
        let service = WallboxService(
            apiClient: WallboxAPIClient(settings: settings, session: URLProtocolStub.makeSession()),
            settings: settings
        )

        try await service.updateChargingSettings(
            ChargingSettings(
                currentSOCPercent: 37,
                targetSOCPercent: 80,
                batterySizeKWh: 42,
                chargingEnergyFactor: 0.85
            )
        )

        let requestedURL = try #require(URLProtocolStub.recordedURLs.last)
        #expect(requestedURL.absoluteString == "http://192.168.178.69/api/set?dwo=21247")
    }

    // MARK: - Helpers

    private func makeClient(json: String, statusCode: Int = 200) -> WallboxAPIClient {
        URLProtocolStub.setStub(statusCode: statusCode, body: Data(json.utf8))
        return WallboxAPIClient(settings: AppSettings(), session: URLProtocolStub.makeSession())
    }
}

/// Serves a canned HTTP response for every request and records the requested URLs.
final class URLProtocolStub: URLProtocol {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var statusCode = 200
    nonisolated(unsafe) private static var body = Data()
    nonisolated(unsafe) private static var urls: [URL] = []

    static func setStub(statusCode: Int, body: Data) {
        lock.lock()
        defer { lock.unlock() }
        self.statusCode = statusCode
        self.body = body
        urls = []
    }

    static var recordedURLs: [URL] {
        lock.lock()
        defer { lock.unlock() }
        return urls
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lock.lock()
        let statusCode = Self.statusCode
        let body = Self.body
        if let url = request.url {
            Self.urls.append(url)
        }
        Self.lock.unlock()

        guard let url = request.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: statusCode,
                  httpVersion: nil,
                  headerFields: nil
              ) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
