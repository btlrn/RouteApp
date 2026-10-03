import SwiftUI
import GoogleMaps

struct MapView: UIViewRepresentable {

    func makeUIView(context: Context) -> GMSMapView {
        
        let options = GMSMapViewOptions()
        
        options.camera = GMSCameraPosition(
            latitude: 41.0082,
            longitude: 28.9784,
            zoom: 11
        )
        
        let mapView = GMSMapView(options: options)
        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        
    }
}
