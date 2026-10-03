//
//  RouteAppApp.swift
//  RouteApp
//
//  Created by BETÜL TURAN on 3.10.2026.
//

import SwiftUI
import GoogleMaps

// : App bir protocol ve body istiyor bizden.
@main
struct RouteAppApp: App {
    
    init() {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
           // GMSServices sınıfının provideAPIKey static metodunu kullanarak apiKey değerimizi gönderdik.
            GMSServices.provideAPIKey(apiKey)
            print("API key yüklendi: \(apiKey.prefix(6))...")
        } else {
            assertionFailure("GMSApiKey Info.plist'te bulunamadı")
        }
   }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
}

    
    
    
    

