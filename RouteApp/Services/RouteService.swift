import Foundation
import CoreLocation

// MARK: - Hatalar

enum RouteError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case noRouteFound

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:   return "API anahtarı bulunamadı."
        case .invalidResponse: return "Sunucudan geçersiz bir cevap geldi."
        case .noRouteFound:    return "Bu iki nokta arasında rota bulunamadı."
        }
    }
}

// MARK: - Sözleşme

protocol RouteServiceProtocol {
    func fetchRoute(from start: CLLocationCoordinate2D,
                    to end: CLLocationCoordinate2D) async throws -> String
}

// MARK: - Gerçek servis

final class RouteService: RouteServiceProtocol {

    private let endpoint = URL(string: "https://routes.googleapis.com/directions/v2:computeRoutes")!

    func fetchRoute(from start: CLLocationCoordinate2D,
                    to end: CLLocationCoordinate2D) async throws -> String {

        // 1. API key'i Info.plist'ten al
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
              !apiKey.isEmpty else {
            throw RouteError.missingAPIKey
        }

        // 2. Body'yi hazırla
        let body = RouteRequest(
            origin: makeWaypoint(start),
            destination: makeWaypoint(end),
            travelMode: "DRIVE"
        )

        // 3. İsteği (mektubu) hazırla
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("routes.polyline.encodedPolyline", forHTTPHeaderField: "X-Goog-FieldMask")
        request.setValue(Bundle.main.bundleIdentifier, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        request.httpBody = try JSONEncoder().encode(body)

        // 4. Gönder ve cevabı bekle
        let (data, response) = try await URLSession.shared.data(for: request)

        // 5. Cevap başarılı mı?
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            print("Routes API hatası:", String(data: data, encoding: .utf8) ?? "-")
            throw RouteError.invalidResponse
        }

        // 6. JSON'u Swift'e çevir ve polyline'ı çıkar
        let decoded = try JSONDecoder().decode(RouteResponse.self, from: data)

        guard let encoded = decoded.routes?.first?.polyline.encodedPolyline else {
            throw RouteError.noRouteFound
        }
        return encoded
    }

    private func makeWaypoint(_ coordinate: CLLocationCoordinate2D) -> RouteWaypoint {
        RouteWaypoint(
            location: RouteLocation(
                latLng: LatLng(latitude: coordinate.latitude,
                               longitude: coordinate.longitude)
            )
        )
    }
}
