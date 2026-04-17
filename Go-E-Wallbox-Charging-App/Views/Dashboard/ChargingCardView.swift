import SwiftUI

struct ChargingCardView: View {
    let status: WallboxStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(format: AppConstants.UI.wallboxStatusFormat, status.connectionStateLabel))
            Text(String(format: AppConstants.UI.chargingPowerFormat, status.chargingPowerW))
            Text(String(format: AppConstants.UI.energyTodayFormat, status.energyPerDayWh))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.secondary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
