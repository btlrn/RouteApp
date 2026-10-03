import SwiftUI

struct PinView: View {

    private let height: CGFloat = 44

    var body: some View {
        Image(systemName: "mappin")
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .foregroundStyle(.red)
            .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
            .offset(y: -height / 2)
            .allowsHitTesting(false)
    }
}

#Preview {
    PinView()
}
