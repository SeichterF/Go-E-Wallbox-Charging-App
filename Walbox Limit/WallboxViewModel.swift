//
//  WallboxViewModel.swift
//  Walbox Limit
//
//  Created by Florian Seichter on 18.02.26.
//

import Foundation
import SwiftUI

/// ViewModel für die Wallbox-Steuerung (MVVM-Pattern)
@MainActor
@Observable
class WallboxViewModel {
    // MARK: - Published Properties
    var selectedAmpere: Int = 16
    var isLoading: Bool = false
    var errorMessage: String?
    var successMessage: String?
    var showingAlert: Bool = false
    
    // MARK: - Configuration
    var wallboxIP: String = "192.168.1.100" {
        didSet {
            updateService()
        }
    }
    
    var apiKey: String = "" {
        didSet {
            updateService()
        }
    }
    
    // MARK: - Private Properties
    private var service: WallboxService
    
    // MARK: - Constants
    let minAmpere = 6
    let maxAmpere = 32
    let commonAmpereValues = [6, 8, 10, 13, 16, 20, 25, 32]
    
    // MARK: - Initialization
    init() {
        // Service mit Default-Werten initialisieren
        let config = WallboxConfig(ipAddress: "192.168.1.100", apiKey: "")
        self.service = WallboxService(config: config)
    }
    
    // MARK: - Public Methods
    
    /// Setzt das Ladelimit auf der Wallbox
    func setChargingLimit() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let response = try await service.setChargingLimit(ampere: selectedAmpere)
            successMessage = "Ladelimit erfolgreich auf \(selectedAmpere)A gesetzt"
            showingAlert = true
        } catch let error as WallboxError {
            errorMessage = error.errorDescription
            showingAlert = true
        } catch {
            errorMessage = "Unerwarteter Fehler: \(error.localizedDescription)"
            showingAlert = true
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func updateService() {
        let config = WallboxConfig(ipAddress: wallboxIP, apiKey: apiKey)
        self.service = WallboxService(config: config)
    }
}
