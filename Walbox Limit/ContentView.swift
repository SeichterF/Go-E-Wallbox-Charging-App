//
//  ContentView.swift
//  Walbox Limit
//
//  Created by Florian Seichter on 18.02.26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = WallboxViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                // Konfiguration-Sektion
                Section {
                    TextField("IP-Adresse", text: $viewModel.wallboxIP)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    SecureField("API-Key", text: $viewModel.apiKey)
                        .textContentType(.password)
                } header: {
                    Text("Wallbox-Konfiguration")
                } footer: {
                    Text("Geben Sie die lokale IP-Adresse Ihrer Wallbox und den API-Key ein.")
                }
                
                // Ladelimit-Sektion
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Ladelimit")
                            Spacer()
                            Text("\(viewModel.selectedAmpere) A")
                                .bold()
                                .foregroundStyle(.tint)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(viewModel.selectedAmpere) },
                                set: { viewModel.selectedAmpere = Int($0) }
                            ),
                            in: Double(viewModel.minAmpere)...Double(viewModel.maxAmpere),
                            step: 1
                        )
                    }
                    
                    // Schnellauswahl für gängige Werte
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.commonAmpereValues, id: \.self) { ampere in
                                Button {
                                    viewModel.selectedAmpere = ampere
                                } label: {
                                    Text("\(ampere)A")
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            viewModel.selectedAmpere == ampere 
                                            ? Color.accentColor 
                                            : Color.secondary.opacity(0.2)
                                        )
                                        .foregroundStyle(
                                            viewModel.selectedAmpere == ampere 
                                            ? .white 
                                            : .primary
                                        )
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Ladestrom einstellen")
                } footer: {
                    Text("Wählen Sie den maximalen Ladestrom zwischen \(viewModel.minAmpere) und \(viewModel.maxAmpere) Ampere.")
                }
                
                // Action-Sektion
                Section {
                    Button {
                        Task {
                            await viewModel.setChargingLimit()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(viewModel.isLoading ? "Wird gesetzt..." : "Ladelimit setzen")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.apiKey.isEmpty)
                }
            }
            .navigationTitle("Wallbox Limit")
            .alert(
                viewModel.errorMessage != nil ? "Fehler" : "Erfolg",
                isPresented: $viewModel.showingAlert
            ) {
                Button("OK") {
                    viewModel.showingAlert = false
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                } else if let successMessage = viewModel.successMessage {
                    Text(successMessage)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
