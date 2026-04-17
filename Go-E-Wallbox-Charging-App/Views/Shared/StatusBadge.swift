import SwiftUI

struct StatusBadge: View {
    let isConnected: Bool

    var body: some View {
        Text(isConnected ? AppConstants.UI.connected : AppConstants.UI.disconnected)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .background(isConnected ? .green : .red)
            .clipShape(Capsule())
    }
}
