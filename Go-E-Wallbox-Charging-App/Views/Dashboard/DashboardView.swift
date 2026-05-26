import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var socFieldFocused: Bool

    init(viewModel: DashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statusCard
                    chargeLimitCard
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(AppConstants.UI.dashboardTitle)
            .task(id: scenePhase == .active) {
                guard scenePhase == .active else { return }
                await viewModel.startPolling()
            }
        }
    }

    // MARK: - Cards

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: viewModel.status.connectionState.iconName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(viewModel.status.connectionState.tintColor)
                Text(viewModel.status.connectionStateLabel)
                    .font(.headline)
                    .foregroundStyle(viewModel.status.connectionState.tintColor)
                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text(AppConstants.UI.dashboardChargingPowerLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(viewModel.status.chargingPowerW)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text(AppConstants.UI.unitWatt)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(AppConstants.UI.dashboardEnergyTodayLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(viewModel.status.energyPerDayWh)")
                            .font(.title3.weight(.semibold))
                        Text(AppConstants.UI.unitWh)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(AppConstants.UI.dashboardEnergyLimitLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if viewModel.status.chargeLimitWh > 0 {
                        Text(String(
                            format: AppConstants.UI.dashboardEnergyLimitValueFormat,
                            Double(viewModel.status.chargeLimitWh) / 1000.0
                        ))
                        .font(.title3.weight(.semibold))
                    } else {
                        Text(AppConstants.UI.noChargeLimitValue)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var chargeLimitCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(AppConstants.UI.dashboardSectionChargeLimit)
                .font(.headline)
                .padding(.bottom, 16)

            socHeroInput

            Divider()
                .padding(.vertical, 16)

            socProgressBar
                .padding(.bottom, 16)

            Divider()

            cardRow(label: AppConstants.UI.calculatedChargeLimitLabel) {
                if viewModel.previewChargeLimitWh > 0 {
                    Text(String(
                        format: AppConstants.UI.calculatedChargeLimitValueFormat,
                        Double(viewModel.previewChargeLimitWh) / 1000.0
                    ))
                    .font(.body.weight(.medium))
                } else {
                    Text(AppConstants.UI.calculatedChargeLimitTargetReached)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var socHeroInput: some View {
        VStack(spacing: 6) {
            Text(AppConstants.UI.currentSOCFieldLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(viewModel.currentSOCText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(socFieldFocused ? Color.accentColor : .primary)
                    Text(AppConstants.UI.unitPercent)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .animation(.easeInOut(duration: 0.15), value: socFieldFocused)

                TextField("", text: Binding(
                    get: { viewModel.currentSOCText },
                    set: { viewModel.replaceCurrentSOCTextWithSanitizedUserInput($0) }
                ))
                .keyboardType(.numberPad)
                .textContentType(.none)
                .autocorrectionDisabled()
                .focused($socFieldFocused)
                .opacity(0.001)
                .frame(maxWidth: .infinity, minHeight: 60)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { socFieldFocused = true }
        }
        .padding(.vertical, 4)
    }

    private var socProgressBar: some View {
        let current = viewModel.parsedCurrentSOCPercent
        let estimated = viewModel.calculatedCurrentSOCPercent
        let target = viewModel.targetSOCPercent
        let targetReached = estimated >= target

        return VStack(spacing: 8) {
            GeometryReader { geo in
                let w = geo.size.width
                let currentX = w * CGFloat(current) / 100.0
                let estimatedX = w * CGFloat(min(estimated, 100)) / 100.0
                let targetX = w * CGFloat(min(target, 100)) / 100.0

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 8)

                    if !targetReached && estimatedX > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.45))
                            .frame(width: estimatedX, height: 8)
                    }

                    if currentX > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green)
                            .frame(width: max(8, currentX), height: 8)
                    }

                    Circle()
                        .stroke(targetReached ? Color.green : Color.secondary.opacity(0.5), lineWidth: 1.5)
                        .background(Circle().fill(Color(.systemBackground)))
                        .frame(width: 12, height: 12)
                        .offset(x: targetX - 6, y: -2)
                }
            }
            .frame(height: 12)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(current) \(AppConstants.UI.unitPercent)")
                        .font(.caption2.weight(.semibold))
                    Text(AppConstants.UI.socProgressNowLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if estimated > current && !targetReached {
                    Spacer()
                    VStack(alignment: .center, spacing: 1) {
                        Text("~\(estimated) \(AppConstants.UI.unitPercent)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.blue.opacity(0.8))
                        Text(AppConstants.UI.socProgressAfterTodayLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(target) \(AppConstants.UI.unitPercent)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(targetReached ? .green : .primary)
                    Text(AppConstants.UI.socProgressTargetLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func cardRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            content()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - ConnectionState view helpers

private extension WallboxStatus.ConnectionState {
    var tintColor: Color {
        switch self {
        case .disconnected, .unknown: return .secondary
        case .idle: return .orange
        case .charging: return .green
        case .waiting: return .yellow
        case .complete: return .blue
        }
    }

    var iconName: String {
        switch self {
        case .disconnected: return "bolt.slash.fill"
        case .idle: return "bolt.fill"
        case .charging: return "bolt.car.fill"
        case .waiting: return "clock.fill"
        case .complete: return "checkmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

#Preview {
    let settings = AppSettings()
    DashboardView(
        viewModel: DashboardViewModel(
            service: WallboxService(
                apiClient: WallboxAPIClient(settings: settings),
                settings: settings
            ),
            settings: settings
        )
    )
}
