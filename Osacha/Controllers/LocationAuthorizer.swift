//
//  LocationAuthorizer.swift
//  Osacha
//
//  Asks iOS for permission to use the customer's location, which delivery
//  and order tracking rely on. Only the request lives here; the app doesn't
//  read location yet.
//

import CoreLocation

@MainActor
final class LocationAuthorizer {
    static let shared = LocationAuthorizer()

    private let manager = CLLocationManager()

    /// Shows the system prompt the first time; after that iOS remembers the
    /// customer's answer and this does nothing.
    func requestPermission() {
        guard manager.authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }
}
