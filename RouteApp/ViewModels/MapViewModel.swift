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

    init(routeService: RouteServiceProtocol = RouteService()) {
        self.routeService = routeService
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
            guard let center else { return }
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
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
                print("Rota hatası:", error)
            }
            isLoading = false
        }
    }
}
