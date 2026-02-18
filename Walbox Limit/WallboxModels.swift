//
//  WallboxModels.swift
//  Walbox Limit
//
//  Created by Florian Seichter on 18.02.26.
//

import Foundation

/// Response-Modell für das Setzen des Ladelimits
struct SetChargingLimitResponse: @unchecked Sendable {
    let status: String?
    let message: String?
    
    init(status: String?, message: String?) {
        self.status = status
        self.message = message
    }
}

// Explizite nonisolated Codable-Conformance
extension SetChargingLimitResponse: Codable {
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(message, forKey: .message)
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
    }
}

/// Request-Modell für das Setzen des Ladelimits
struct SetChargingLimitRequest: @unchecked Sendable {
    let maxChargingCurrent: Int
    
    init(maxChargingCurrent: Int) {
        self.maxChargingCurrent = maxChargingCurrent
    }
    
    enum CodingKeys: String, CodingKey {
        case maxChargingCurrent = "max_charging_current"
    }
}

// Explizite nonisolated Codable-Conformance
extension SetChargingLimitRequest: Codable {
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(maxChargingCurrent, forKey: .maxChargingCurrent)
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        maxChargingCurrent = try container.decode(Int.self, forKey: .maxChargingCurrent)
    }
}

/// Konfiguration für die Wallbox-Verbindung
struct WallboxConfig: Sendable {
    let baseURL: String
    let apiKey: String
    
    /// Standard-Konstruktor für lokale Wallbox
    init(ipAddress: String = "192.168.1.100", apiKey: String) {
        self.baseURL = "http://\(ipAddress)"
        self.apiKey = apiKey
    }
}
