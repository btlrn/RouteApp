import Foundation
import CoreLocation
import Observation

// Trafik ışığı: aynı anda sadece biri olabilir
enum SelectionState {
    case selectingStart
    case selectingEnd
    case ready
}

// Müdür
@MainActor
@Observable
final class MapViewModel {

    // Pin'in şu an gösterdiği yer (haritadan gelir)
    var center: CLLocationCoordinate2D?

    // Sadece müdür değiştirebilir, herkes okuyabilir
    private(set) var startPoint: CLLocationCoordinate2D?
    private(set) var endPoint: CLLocationCoordinate2D?
    private(set) var state: SelectionState = .selectingStart

    // Rota bilgileri
    private(set) var encodedPolyline: String?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // Müdürün rota uzmanı (dışarıdan verilir)
    private let routeService: RouteServiceProtocol
    // Devam eden rota isteği (iptal edebilmek için saklıyoruz)
    private var routeTask: Task<Void, Never>?

    // Başlangıç ve bitiş bundan yakınsa "aynı nokta" sayılır (metre)
    private let minimumDistance: CLLocationDistance = 20

    init(routeService: RouteServiceProtocol? = nil) {
        self.routeService = routeService ?? RouteService()
    }
    // Butonda ne yazacağına ışığa bakarak karar verir
    var buttonTitle: String {
        switch state {
        case .selectingStart: return "Başlangıç olarak seç"
        case .selectingEnd:   return "Bitiş olarak seç"
        case .ready:          return "Sıfırla"
        }
    }

    // Butona basılınca ne olacağına karar verir
    func confirmSelection() {
        switch state {
        case .selectingStart:
            guard let center else { return }
            startPoint = center
            state = .selectingEnd
        case .selectingEnd:
            guard let center, let startPoint else { return }
            // Uç durum 1: bitiş, başlangıçla aynı yerdeyse istek atma
            guard distance(from: startPoint, to: center) >= minimumDistance else {
                errorMessage = "Başlangıç ve bitiş noktası aynı olamaz. Haritayı kaydırıp başka bir nokta seç."
                return
            }
            endPoint = center
            state = .ready
            loadRoute()
        case .ready:
            reset()
        }
    }

    func reset() {
        routeTask?.cancel()
        routeTask = nil
        startPoint = nil
        endPoint = nil
        encodedPolyline = nil
        isLoading = false
        errorMessage = nil
        state = .selectingStart
    }

    // Kullanıcı hata uyarısını kapatınca çağrılır
    func dismissError() {
        errorMessage = nil
    }

    // İki koordinat arasındaki mesafe (metre)
    private func distance(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> CLLocationDistance {
        let locationA = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let locationB = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return locationA.distance(from: locationB)
    }

    // Uzmana rotayı sorar
    private func loadRoute() {
        guard let startPoint, let endPoint else { return }

        routeTask?.cancel()
        isLoading = true
        errorMessage = nil

        routeTask = Task {
            do {
                let polyline = try await routeService.fetchRoute(from: startPoint, to: endPoint)
                guard !Task.isCancelled else { return }
                encodedPolyline = polyline
            } catch let error as RouteError {
                // Uç durum 2: bizim hatalarımız (rota yok, cevap bozuk...) → anlaşılır mesaj
                guard !Task.isCancelled else { return }
                errorMessage = "Bu iki nokta arasında rota bulunamadı. Başka bir nokta dene."
                print("Rota hatası:", error)
            } catch {
                // Sistem hataları (internet yok gibi) → Apple'ın hazır mesajı
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
                print("Rota hatası:", error)
            }
            isLoading = false
        }
    }
}
