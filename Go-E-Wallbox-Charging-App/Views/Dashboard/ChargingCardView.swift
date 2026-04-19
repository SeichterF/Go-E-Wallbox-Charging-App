import SwiftUI

struct ChargingCardView: View {
    let status: WallboxStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(format: AppConstants.UI.wallboxStatusFormat, status.connectionStateLabel))
            Text(String(format: AppConstants.UI.chargingPowerFormat, status.chargingPowerW))
            Text(String(format: AppConstants.UI.energyTodayFormat, status.energyPerDayWh))
            if status.chargeLimitWh > 0 {
                Text(
                    String(
                        format: AppConstants.UI.energyLimitWhFormat,
                        Double(status.chargeLimitWh) / 1000.0,
                        status.chargeLimitWh
                    )
                )
            } else {
                Text(AppConstants.UI.noChargeLimit)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.secondary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
