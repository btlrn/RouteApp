import SwiftUI
import GoogleMaps

struct MapView: UIViewRepresentable {

    var startPoint: CLLocationCoordinate2D?
    var endPoint: CLLocationCoordinate2D?
    var encodedPolyline: String?
    var userLocation: CLLocationCoordinate2D?
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
        mapView.isMyLocationEnabled = true   // kullanıcının mavi noktası
        return mapView
    }

    // SwiftUI'daki durum değişince haritayı ona uydurur
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        context.coordinator.onCameraIdle = onCameraIdle
        context.coordinator.centerOnUser(on: uiView, location: userLocation)
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

        // Araba ve animasyon numarası (eski animasyonları durdurmak için)
        private var carMarker: GMSMarker?
        private var animationID = 0

        // Kullanıcıya bir kere odaklandık mı? (her güncellemede kamerayı zıplatmamak için)
        private var hasCenteredOnUser = false

        init(onCameraIdle: @escaping (CLLocationCoordinate2D) -> Void) {
            self.onCameraIdle = onCameraIdle
        }

        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            onCameraIdle(position.target)
        }

        // MARK: - Kullanıcı konumu

        func centerOnUser(on mapView: GMSMapView, location: CLLocationCoordinate2D?) {
            // Konum yoksa, zaten odaklandıysak ya da rota çiziliyse kameraya dokunma
            guard let location, !hasCenteredOnUser, drawnPath == nil else { return }
            hasCenteredOnUser = true
            mapView.animate(to: GMSCameraPosition(target: location, zoom: 14))
        }

        // MARK: - Marker'lar

        func updateMarkers(on mapView: GMSMapView,
                           start: CLLocationCoordinate2D?,
                           end: CLLocationCoordinate2D?) {
            startMarker = updateMarker(startMarker, at: start, color: .systemGreen, title: "Başlangıç", on: mapView)
            endMarker = updateMarker(endMarker, at: end, color: .systemRed, title: "Bitiş", on: mapView)
        }

        // MARK: - Rota

        func updateRoute(on mapView: GMSMapView, encodedPath: String?) {
            // Rota değişmediyse hiçbir şey yapma (sonsuz döngü koruması)
            guard encodedPath != drawnPath else { return }
            drawnPath = encodedPath

            // Eski çizgiyi ve arabayı kaldır
            routeLine?.map = nil
            routeLine = nil
            stopCar()

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

            // Arabayı yola çıkar
            startCar(along: path, on: mapView)
        }

        // MARK: - Araba animasyonu

        private func startCar(along path: GMSPath, on mapView: GMSMapView) {
            // En az iki nokta yoksa gidilecek yol yok
            guard path.count() > 1 else { return }

            let first = path.coordinate(at: 0)
            let second = path.coordinate(at: 1)

            let marker = GMSMarker(position: first)
            marker.icon = carIcon()
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5) // ikonun ortası koordinata otursun
            marker.isFlat = true                          // harita döndükçe ikon da onunla dönsün
            marker.zIndex = 10                            // diğer marker'ların üstünde dursun
            marker.rotation = GMSGeometryHeading(first, second)
            marker.map = mapView
            carMarker = marker

            // Yeni animasyon başlıyor: numarayı artır
            animationID += 1
            moveCar(along: path, toIndex: 1, id: animationID)
        }

        private func moveCar(along path: GMSPath, toIndex index: UInt, id: Int) {
            // Bu animasyon iptal edildiyse, araba yoksa ya da yol bittiyse dur
            guard id == animationID,
                  let marker = carMarker,
                  index < path.count() else { return }

            let from = marker.position
            let to = path.coordinate(at: index)

            // Mesafeye göre süre: kısa parça hızlı, uzun parça daha yavaş geçilir
            let distance = GMSGeometryDistance(from, to)        // metre
            let duration = min(max(distance / 300, 0.05), 1.0)  // saniye

            CATransaction.begin()
            CATransaction.setAnimationDuration(duration)
            CATransaction.setCompletionBlock { [weak self] in
                // Bu parça bitti, sıradaki noktaya geç
                self?.moveCar(along: path, toIndex: index + 1, id: id)
            }
            marker.rotation = GMSGeometryHeading(from, to)
            marker.position = to
            CATransaction.commit()
        }

        private func stopCar() {
            // Numarayı artırınca çalışan eski zincir kendi kendine durur
            animationID += 1
            carMarker?.map = nil
            carMarker = nil
        }

        private func carIcon() -> UIImage? {
            let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
            return UIImage(systemName: "location.north.fill", withConfiguration: config)?
                .withTintColor(.systemOrange, renderingMode: .alwaysOriginal)
        }

        // MARK: - Marker yardımcısı

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
