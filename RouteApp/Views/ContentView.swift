import SwiftUI

struct ContentView: View {

    @State private var viewModel = MapViewModel()

    var body: some View {
        MapView(
            startPoint: viewModel.startPoint,
            endPoint: viewModel.endPoint,
            encodedPolyline: viewModel.encodedPolyline
        ) { coordinate in
            viewModel.center = coordinate
        }
        .overlay {
            if viewModel.state != .ready {
                PinView()
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Rota hesaplanıyor...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            Button {
                viewModel.confirmSelection()
            } label: {
                Text(viewModel.buttonTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.brand, in: Capsule())
            }
            .disabled(viewModel.isLoading)
            .padding(.bottom, 40)
        }
        .alert("Bir sorun oluştu", isPresented: errorBinding) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // Alert "açık mı?" diye bir Bool ister; biz bunu errorMessage'dan türetiyoruz
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented { viewModel.dismissError() }
            }
        )
    }
}
