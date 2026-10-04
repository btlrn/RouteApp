import SwiftUI
import GoogleMaps

struct MapView: UIViewRepresentable {

    var startPoint: CLLocationCoordinate2D?
    var endPoint: CLLocationCoordinate2D?
    var encodedPolyline: String?
    var onCameraIdle: (CLLocationCoordinate2D) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCameraIdle: onCameraIdle)
    }

    func makeUIView(context: Context) -> GMSMapView {
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition(
            latitude: 41.0082,
            longitude: 28.9784,
            zoom: 11
        )
        let mapView = GMSMapView(options: options)
        mapView.paddingAdjustmentBehavior = .never
        mapView.delegate = context.coordinator
        return mapView
    }

    // SwiftUI'daki durum değişince haritayı ona uydurur
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        context.coordinator.onCameraIdle = onCameraIdle
        context.coordinator.updateMarkers(on: uiView, start: startPoint, end: endPoint)
        context.coordinator.updateRoute(on: uiView, encodedPath: encodedPolyline)
    }

    class Coordinator: NSObject, GMSMapViewDelegate {
        var onCameraIdle: (CLLocationCoordinate2D) -> Void

        // Marker'ları asistan saklar ki her seferinde yenisini yaratmayalım
        private var startMarker: GMSMarker?
        private var endMarker: GMSMarker?

        // Çizili rota ve hangi rotayı çizdiğimiz
        private var routeLine: GMSPolyline?
        private var drawnPath: String?

        init(onCameraIdle: @escaping (CLLocationCoordinate2D) -> Void) {
            self.onCameraIdle = onCameraIdle
        }

        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            onCameraIdle(position.target)
        }

        func updateMarkers(on mapView: GMSMapView,
                           start: CLLocationCoordinate2D?,
                           end: CLLocationCoordinate2D?) {
            startMarker = updateMarker(startMarker, at: start, color: .systemGreen, title: "Başlangıç", on: mapView)
            endMarker = updateMarker(endMarker, at: end, color: .systemRed, title: "Bitiş", on: mapView)
        }

        func updateRoute(on mapView: GMSMapView, encodedPath: String?) {
            // Rota değişmediyse hiçbir şey yapma (sonsuz döngü koruması)
            guard encodedPath != drawnPath else { return }
            drawnPath = encodedPath

            // Eski çizgiyi kaldır
            routeLine?.map = nil
            routeLine = nil

            // Yeni rota yoksa (sıfırlandıysa) burada dur
            guard let encodedPath,
                  let path = GMSPath(fromEncodedPath: encodedPath) else { return }

            // Çizgiyi çiz
            let line = GMSPolyline(path: path)
            line.strokeWidth = 5
            line.strokeColor = .systemBlue
            line.map = mapView
            routeLine = line

            // Kamerayı rotaya sığdır
            let bounds = GMSCoordinateBounds(path: path)
            mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 60))
        }

        private func updateMarker(_ marker: GMSMarker?,
                                  at coordinate: CLLocationCoordinate2D?,
                                  color: UIColor,
                                  title: String,
                                  on mapView: GMSMapView) -> GMSMarker? {
            // Koordinat yoksa marker'ı haritadan kaldır
            guard let coordinate else {
                marker?.map = nil
                return nil
            }
            // Varsa eskisini kullan, yoksa yeni oluştur
            let marker = marker ?? GMSMarker()
            marker.position = coordinate
            marker.title = title
            marker.icon = GMSMarker.markerImage(with: color)
            marker.map = mapView
            return marker
        }
    }
}
