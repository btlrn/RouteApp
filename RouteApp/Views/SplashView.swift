import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.blue
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "map.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)

                Text("RouteApp")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Rotanı çiz, yola çık")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    SplashView()
}
