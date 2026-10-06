import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "mappin.and.ellipse",
            title: "Noktalarını Seç",
            text: "Haritayı kaydırarak ortadaki pin ile başlangıç ve bitiş noktanı belirle."
        ),
        OnboardingPage(
            icon: "car.fill",
            title: "Rotanı İzle",
            text: "Rotan anında çizilsin, araba yol boyunca ilerlesin. İstediğin zaman sıfırlayıp yeniden başla."
        )
    ]

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Atla") { onFinish() }
                    .foregroundColor(.secondary)
                    .padding()
            }

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    onFinish()
                }
            } label: {
                Text(page < pages.count - 1 ? "Devam" : "Başla")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.brand, in: Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(Color.brand)

            Text(page.title)
                .font(.title.bold())

            Text(page.text)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let text: String
}

#Preview {
    OnboardingView { }
}
