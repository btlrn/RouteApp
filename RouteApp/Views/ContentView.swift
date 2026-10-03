import SwiftUI

struct ContentView: View {

    @State private var viewModel = MapViewModel()

    var body: some View {
        MapView(
            startPoint: viewModel.startPoint,
            endPoint: viewModel.endPoint
        ) { coordinate in
            viewModel.center = coordinate
        }
        .overlay {
            if viewModel.state != .ready {
                PinView()
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
                    .background(.blue, in: Capsule())
            }
            .padding(.bottom, 40)
        }
    }
}
