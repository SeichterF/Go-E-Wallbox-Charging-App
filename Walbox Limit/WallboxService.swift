//
//  WallboxService.swift
//  Walbox Limit
//
//  Created by Florian Seichter on 18.02.26.
//

import Foundation

/// Service-Klasse für die Kommunikation mit der Wallbox API
actor WallboxService {
    private let config: WallboxConfig
    private let session: URLSession
    
    init(config: WallboxConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }
    
    /// Setzt das maximale Ladelimit der Wallbox
    /// - Parameter ampere: Der gewünschte Ladestrom in Ampere (typischerweise 6-32A)
    /// - Returns: Response mit Status
    func setChargingLimit(ampere: Int) async throws -> SetChargingLimitResponse {
        guard ampere >= 6 && ampere <= 32 else {
            throw WallboxError.invalidAmpereValue
        }
        
        // Endpoint für das Setzen des Ladelimits
        let endpoint = "\(config.baseURL)/api/v1/charger/config"
        
        guard let url = URL(string: endpoint) else {
            throw WallboxError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = await SetChargingLimitRequest(maxChargingCurrent: ampere)
        
        // Encoding kann jetzt direkt erfolgen, da Conformance nonisolated ist
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WallboxError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw WallboxError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Versuche die Response zu dekodieren, oder erstelle eine Erfolgsantwort
        if let decodedResponse = try? JSONDecoder().decode(SetChargingLimitResponse.self, from: data) {
            return decodedResponse
        } else {
            return await SetChargingLimitResponse(status: "success", message: "Ladelimit erfolgreich gesetzt")
        }
    }
}

/// Fehlertypen für die Wallbox-Kommunikation
enum WallboxError: LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case invalidAmpereValue
    case httpError(statusCode: Int)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige URL"
        case .invalidResponse:
            return "Ungültige Antwort vom Server"
        case .invalidAmpereValue:
            return "Ampere-Wert muss zwischen 6 und 32 liegen"
        case .httpError(let statusCode):
            return "HTTP-Fehler: \(statusCode)"
        case .networkError:
            return "Netzwerkfehler"
        }
    }
}
