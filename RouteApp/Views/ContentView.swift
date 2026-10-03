import SwiftUI
import CoreLocation

struct ContentView: View {

    // Pin'in gösterdiği son koordinat
    @State private var center: CLLocationCoordinate2D?

    var body: some View {
        MapView { coordinate in
            center = coordinate
        }
        .overlay {
            PinView()
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            if let center {
                Text(String(format: "%.5f, %.5f", center.latitude, center.longitude))
                    .padding(8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding(.bottom, 40)
            }
        }
    }
}
