import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var socFieldFocused: Bool
    @FocusState private var targetFieldFocused: Bool

    private static let progressBarCoordinateSpace = "socProgressBar"

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
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(AppConstants.UI.dashboardTitle)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(AppConstants.UI.done) {
                        socFieldFocused = false
                        targetFieldFocused = false
                    }
                }
            }
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
                    Text(String(format: "%.3f", Double(viewModel.status.chargingPowerW) / 1000.0))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text(AppConstants.UI.unitKW)
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
                        Text(String(format: "%.1f", Double(viewModel.status.energyPerDayWh) / 1000.0))
                            .font(.title3.weight(.semibold))
                        Text(AppConstants.UI.unitKWh)
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

    private var socProgressBar: some View {
        let current = viewModel.displayedCurrentSOCPercent
        let estimated = viewModel.calculatedCurrentSOCPercent
        let target = viewModel.displayedTargetSOCPercent
        let targetReached = estimated >= target
        let isDraggingCurrent = viewModel.currentSOCDragValue != nil
        let isDraggingTarget = viewModel.targetSOCDragValue != nil

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

                    // Current SOC dot
                    Circle()
                        .stroke(Color.green, lineWidth: 1.5)
                        .background(Circle().fill(Color(.systemBackground)))
                        .frame(width: 12, height: 12)
                        .scaleEffect(isDraggingCurrent ? 1.5 : 1.0)
                        .contentShape(Circle().inset(by: -14))
                        .offset(x: currentX - 6, y: -2)
                        .highPriorityGesture(
                            DragGesture(
                                minimumDistance: 0,
                                coordinateSpace: .named(Self.progressBarCoordinateSpace)
                            )
                            .onChanged { value in
                                guard w > 0 else { return }
                                viewModel.updateCurrentSOCDrag(fraction: value.location.x / w)
                            }
                            .onEnded { _ in
                                viewModel.commitCurrentSOCDrag()
                            }
                        )
                        .animation(.easeInOut(duration: 0.15), value: isDraggingCurrent)

                    // Target SOC dot
                    Circle()
                        .stroke(targetReached ? Color.green : Color.secondary.opacity(0.5), lineWidth: 1.5)
                        .background(Circle().fill(Color(.systemBackground)))
                        .frame(width: 12, height: 12)
                        .scaleEffect(isDraggingTarget ? 1.5 : 1.0)
                        .contentShape(Circle().inset(by: -14))
                        .offset(x: targetX - 6, y: -2)
                        .highPriorityGesture(
                            DragGesture(
                                minimumDistance: 0,
                                coordinateSpace: .named(Self.progressBarCoordinateSpace)
                            )
                            .onChanged { value in
                                guard w > 0 else { return }
                                viewModel.updateTargetSOCDrag(fraction: value.location.x / w)
                            }
                            .onEnded { _ in
                                viewModel.commitTargetSOCDrag()
                            }
                        )
                        .animation(.easeInOut(duration: 0.15), value: isDraggingTarget)
                }
                .coordinateSpace(name: Self.progressBarCoordinateSpace)
            }
            .frame(height: 12)

            HStack(alignment: .top) {
                currentValueLabel(current: current)

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

                targetValueLabel(target: target, targetReached: targetReached)
            }

            if let error = viewModel.socValidationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let error = viewModel.targetSOCValidationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.socValidationError != nil)
        .animation(.easeInOut(duration: 0.2), value: viewModel.targetSOCValidationError != nil)
    }

    private func currentValueLabel(current: Int) -> some View {
        let displayedText = socFieldFocused
            ? (viewModel.currentSOCText.isEmpty ? "0" : viewModel.currentSOCText)
            : "\(current)"

        return VStack(alignment: .leading, spacing: 1) {
            ZStack {
                Text("\(displayedText) \(AppConstants.UI.unitPercent)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(
                        viewModel.socValidationError != nil ? Color.red :
                        viewModel.socFieldIsCleared ? Color.secondary.opacity(0.3) :
                        socFieldFocused ? Color.accentColor : Color.primary
                    )

                TextField("", text: Binding(
                    get: { viewModel.currentSOCText },
                    set: { viewModel.replaceCurrentSOCTextWithSanitizedUserInput($0) }
                ))
                .keyboardType(.numberPad)
                .textContentType(.none)
                .autocorrectionDisabled()
                .focused($socFieldFocused)
                .opacity(0.001)
                .frame(width: 44, height: 18)
            }
            Text(AppConstants.UI.socProgressCurrentLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture { socFieldFocused = true }
        .onChange(of: socFieldFocused) { _, focused in
            if focused { viewModel.beginEditing() } else { viewModel.endEditing() }
        }
    }

    private func targetValueLabel(target: Int, targetReached: Bool) -> some View {
        let displayedText = targetFieldFocused
            ? (viewModel.targetSOCText.isEmpty ? "0" : viewModel.targetSOCText)
            : "\(target)"

        return VStack(alignment: .trailing, spacing: 1) {
            ZStack {
                Text("\(displayedText) \(AppConstants.UI.unitPercent)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(
                        viewModel.targetSOCValidationError != nil ? Color.red :
                        viewModel.targetSOCFieldIsCleared ? Color.secondary.opacity(0.3) :
                        targetFieldFocused ? Color.accentColor :
                        targetReached ? Color.green : Color.primary
                    )

                TextField("", text: Binding(
                    get: { viewModel.targetSOCText },
                    set: { viewModel.replaceTargetSOCTextWithSanitizedUserInput($0) }
                ))
                .keyboardType(.numberPad)
                .textContentType(.none)
                .autocorrectionDisabled()
                .focused($targetFieldFocused)
                .opacity(0.001)
                .frame(width: 44, height: 18)
            }
            Text(AppConstants.UI.socProgressTargetLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture { targetFieldFocused = true }
        .onChange(of: targetFieldFocused) { _, focused in
            if focused { viewModel.beginEditingTargetSOC() } else { viewModel.endEditingTargetSOC() }
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
        case .charging: return .green
        case .waiting: return .yellow
        case .complete: return .blue
        }
    }

    var iconName: String {
        switch self {
        case .disconnected: return "bolt.slash.fill"
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
