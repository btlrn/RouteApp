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
@Observable
final class MapViewModel {

    // Pin'in şu an gösterdiği yer (haritadan gelir)
    var center: CLLocationCoordinate2D?

    // Sadece müdür değiştirebilir, herkes okuyabilir
    private(set) var startPoint: CLLocationCoordinate2D?
    private(set) var endPoint: CLLocationCoordinate2D?
    private(set) var state: SelectionState = .selectingStart

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
        case .ready:
            reset()
        }
    }

    func reset() {
        startPoint = nil
        endPoint = nil
        state = .selectingStart
    }
}
