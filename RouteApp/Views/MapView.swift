import SwiftUI
import GoogleMaps

struct MapView: UIViewRepresentable {

    // Harita durunca çağrılacak fonksiyon (ContentView verecek)
    var onCameraIdle: (CLLocationCoordinate2D) -> Void

    // 1) SwiftUI bunu bir kez çağırır ve Coordinator'ı saklar
    func makeCoordinator() -> Coordinator {
        Coordinator(onCameraIdle: onCameraIdle)
    }

    // 2) Harita bir kez oluşturulur
    func makeUIView(context: Context) -> GMSMapView {
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition(
            latitude: 41.0082,
            longitude: 28.9784,
            zoom: 11
        )
        let mapView = GMSMapView(options: options)
        mapView.paddingAdjustmentBehavior = .never
        mapView.delegate = context.coordinator   // "Bir şey olursa Coordinator'a haber ver"
        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        context.coordinator.onCameraIdle = onCameraIdle
    }

    // 3) Haritanın haber verdiği "temsilci"
    class Coordinator: NSObject, GMSMapViewDelegate {
        var onCameraIdle: (CLLocationCoordinate2D) -> Void

        init(onCameraIdle: @escaping (CLLocationCoordinate2D) -> Void) {
            self.onCameraIdle = onCameraIdle
        }

        // Google, harita durunca bu metodu kendisi çağırır
        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            onCameraIdle(position.target)   // merkezi ContentView'a ilet
        }
    }
}
