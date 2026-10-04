import Foundation

// MARK: - İstek (Google'a gönderdiğimiz)

struct RouteRequest: Encodable {
    let origin: RouteWaypoint
    let destination: RouteWaypoint
    let travelMode: String
}

struct RouteWaypoint: Encodable {
    let location: RouteLocation
}

struct RouteLocation: Encodable {
    let latLng: LatLng
}

struct LatLng: Encodable {
    let latitude: Double
    let longitude: Double
}

// MARK: - Cevap (Google'dan gelen)

struct RouteResponse: Decodable {
    let routes: [Route]?
}

struct Route: Decodable {
    let polyline: RoutePolyline
}

struct RoutePolyline: Decodable {
    let encodedPolyline: String
}
