//
//  GoogleMapView.swift
//  ReliefBox
//
//  Created by Diyorbek Ibragimov on 31/01/2025.
//

import SwiftUI
import GoogleMaps

struct GoogleMapView: UIViewRepresentable {
    @Binding var markers: [GMSMarker]
    @Binding var userLocation: CLLocationCoordinate2D?
    @Binding var forceRecenter: Bool

    func makeUIView(context: Context) -> GMSMapView {
        return MapHolder.shared.mapView // Singleton instance
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear()
        markers.forEach { $0.map = mapView }

        if forceRecenter, let userLocation = userLocation {
            let camera = GMSCameraPosition.camera(
                withLatitude: userLocation.latitude,
                longitude: userLocation.longitude,
                zoom: 12
            )
            mapView.animate(to: camera)
            DispatchQueue.main.async {
                self.forceRecenter = false
            }
        }
    }
}

// Singleton to hold the map instance
class MapHolder {
    static let shared = MapHolder()
    let mapView: GMSMapView

    private init() {
        print("MapHolder initialized") // Debug
        let camera = GMSCameraPosition.camera(
            withLatitude: 25.3548,
            longitude: 51.1839,
            zoom: 10
        )
        mapView = GMSMapView(frame: .zero, camera: camera)
        mapView.isMyLocationEnabled = true
    }
}
