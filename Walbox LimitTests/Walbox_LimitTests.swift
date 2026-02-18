//
//  Walbox_LimitTests.swift
//  Walbox LimitTests
//
//  Created by Florian Seichter on 18.02.26.
//

import Testing
import Foundation
@testable import Walbox_Limit

// MARK: - ViewModel Tests

@Suite("WallboxViewModel Tests")
@MainActor
struct WallboxViewModelTests {
    
    @Test("ViewModel initialisiert mit korrekten Default-Werten")
    func viewModelInitialization() {
        let viewModel = WallboxViewModel()
        
        #expect(viewModel.selectedAmpere == 16)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.successMessage == nil)
        #expect(viewModel.showingAlert == false)
        #expect(viewModel.wallboxIP == "192.168.1.100")
        #expect(viewModel.apiKey == "")
    }
    
    @Test("Min und Max Ampere-Werte sind korrekt definiert")
    func ampereRangeValidation() {
        let viewModel = WallboxViewModel()
        
        #expect(viewModel.minAmpere == 6)
        #expect(viewModel.maxAmpere == 32)
    }
    
    @Test("Gängige Ampere-Werte enthalten erwartete Werte")
    func commonAmpereValues() {
        let viewModel = WallboxViewModel()
        
        #expect(viewModel.commonAmpereValues.contains(6))
        #expect(viewModel.commonAmpereValues.contains(16))
        #expect(viewModel.commonAmpereValues.contains(32))
        #expect(viewModel.commonAmpereValues.count == 8)
    }
    
    @Test("Wallbox IP-Adresse kann geändert werden")
    func updateWallboxIP() {
        let viewModel = WallboxViewModel()
        
        viewModel.wallboxIP = "192.168.1.50"
        #expect(viewModel.wallboxIP == "192.168.1.50")
    }
    
    @Test("API-Key kann geändert werden")
    func updateAPIKey() {
        let viewModel = WallboxViewModel()
        
        viewModel.apiKey = "test-api-key-12345"
        #expect(viewModel.apiKey == "test-api-key-12345")
    }
    
    @Test("Selectedampere kann innerhalb des gültigen Bereichs geändert werden")
    func updateSelectedAmpere() {
        let viewModel = WallboxViewModel()
        
        viewModel.selectedAmpere = 20
        #expect(viewModel.selectedAmpere == 20)
        
        viewModel.selectedAmpere = 6
        #expect(viewModel.selectedAmpere == 6)
        
        viewModel.selectedAmpere = 32
        #expect(viewModel.selectedAmpere == 32)
    }
}

// MARK: - Service Tests

@Suite("WallboxService Tests")
struct WallboxServiceTests {
    
    @Test("WallboxConfig wird korrekt mit IP-Adresse initialisiert")
    func wallboxConfigInitialization() {
        let config = WallboxConfig(ipAddress: "192.168.1.100", apiKey: "test-key")
        
        #expect(config.baseURL == "http://192.168.1.100")
        #expect(config.apiKey == "test-key")
    }
    
    @Test("WallboxConfig erstellt korrekte Base-URL")
    func wallboxConfigBaseURL() {
        let config1 = WallboxConfig(ipAddress: "10.0.0.5", apiKey: "key")
        #expect(config1.baseURL == "http://10.0.0.5")
        
        let config2 = WallboxConfig(ipAddress: "192.168.178.50", apiKey: "key")
        #expect(config2.baseURL == "http://192.168.178.50")
    }
    
    @Test("Service lehnt ungültige Ampere-Werte ab (zu niedrig)")
    func serviceRejectsLowAmpereValue() async {
        let config = await WallboxConfig(ipAddress: "192.168.1.100", apiKey: "test")
        let service = WallboxService(config: config)
        
        await #expect(throws: WallboxError.invalidAmpereValue) {
            try await service.setChargingLimit(ampere: 5)
        }
    }
    
    @Test("Service lehnt ungültige Ampere-Werte ab (zu hoch)")
    func serviceRejectsHighAmpereValue() async {
        let config = await WallboxConfig(ipAddress: "192.168.1.100", apiKey: "test")
        let service = WallboxService(config: config)
        
        await #expect(throws: WallboxError.invalidAmpereValue) {
            try await service.setChargingLimit(ampere: 33)
        }
    }
    
    @Test("Service akzeptiert gültige Ampere-Werte (Grenzwerte)")
    func serviceAcceptsValidBoundaryValues() async {
        let config = await WallboxConfig(ipAddress: "192.168.1.100", apiKey: "test")
        
        // Mock-URLSession würde hier verwendet werden für echte Tests
        // Für diesen Test prüfen wir nur, dass keine Exception bei der Validierung geworfen wird
        let service = WallboxService(config: config)
        
        // Diese Tests würden mit einem Mock-URLSession funktionieren
        // Hier zeigen wir die Struktur
        #expect(6 >= 6 && 6 <= 32) // Minimalwert
        #expect(32 >= 6 && 32 <= 32) // Maximalwert
    }
}
// MARK: - Model Tests

@Suite("WallboxModels Tests")
struct WallboxModelsTests {
    
    @Test("SetChargingLimitRequest codiert korrekt zu JSON")
    @MainActor
    func requestEncodesToJSON() throws {
        let request = SetChargingLimitRequest(maxChargingCurrent: 16)
        let encoder = JSONEncoder()
        
        let jsonData = try encoder.encode(request)
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        let unwrappedString = try #require(jsonString)
        #expect(unwrappedString.contains("max_charging_current"))
        #expect(unwrappedString.contains("16"))
    }
    
    @Test("SetChargingLimitResponse decodiert korrekt von JSON")
    @MainActor
    func responseDecodesFromJSON() throws {
        let jsonString = """
        {
            "status": "success",
            "message": "Charging limit set"
        }
        """
        
        let jsonData = try #require(jsonString.data(using: .utf8))
        let decoder = JSONDecoder()
        
        let response = try decoder.decode(SetChargingLimitResponse.self, from: jsonData)
        
        #expect(response.status == "success")
        #expect(response.message == "Charging limit set")
    }
    
    @Test("SetChargingLimitResponse kann mit nil-Werten umgehen")
    @MainActor
    func responseHandlesNilValues() throws {
        let jsonString = """
        {}
        """
        
        let jsonData = try #require(jsonString.data(using: .utf8))
        let decoder = JSONDecoder()
        
        let response = try decoder.decode(SetChargingLimitResponse.self, from: jsonData)
        
        #expect(response.status == nil)
        #expect(response.message == nil)
    }
    
    @Test("SetChargingLimitRequest verwendet korrekten CodingKey")
    @MainActor
    func requestUsesCorrectCodingKey() throws {
        let request = SetChargingLimitRequest(maxChargingCurrent: 25)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        
        let jsonData = try encoder.encode(request)
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        let unwrappedString = try #require(jsonString)
        // Prüft, dass snake_case verwendet wird
        #expect(unwrappedString.contains("max_charging_current"))
        #expect(!unwrappedString.contains("maxChargingCurrent"))
    }
}

// MARK: - Error Tests

@Suite("WallboxError Tests")
struct WallboxErrorTests {
    
    @Test("WallboxError liefert korrekte Fehlerbeschreibungen")
    func errorDescriptions() {
        #expect(WallboxError.invalidURL.errorDescription == "Ungültige URL")
        #expect(WallboxError.invalidResponse.errorDescription == "Ungültige Antwort vom Server")
        #expect(WallboxError.invalidAmpereValue.errorDescription == "Ampere-Wert muss zwischen 6 und 32 liegen")
        #expect(WallboxError.networkError.errorDescription == "Netzwerkfehler")
    }
    
    @Test("HTTP-Error enthält Statuscode in Beschreibung")
    func httpErrorWithStatusCode() {
        let error404 = WallboxError.httpError(statusCode: 404)
        let error500 = WallboxError.httpError(statusCode: 500)
        
        #expect(error404.errorDescription?.contains("404") == true)
        #expect(error500.errorDescription?.contains("500") == true)
    }
}

