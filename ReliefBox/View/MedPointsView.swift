//
//  MedPointsView.swift
//  ReliefBox
//
//  Created by Diyorbek Ibragimov on 31/01/2025.
//

import SwiftUI
import GoogleMaps
import CoreLocation

struct MedPointsView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var markers: [GMSMarker] = []
    @State private var forceRecenter = false

    var body: some View {
        ZStack {
            // Google Map View
            GoogleMapView(
                markers: $markers,
                userLocation: $locationManager.userLocation,
                forceRecenter: $forceRecenter
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea([.bottom]) // Only ignore bottom safe area

            // "Center to My Location" Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        forceRecenter = true
                        locationManager.requestLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: .gray, radius: 4, x: 0, y: 2)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 70) // Match navigation bar height + spacing
                }
            }
        }
        .onAppear {
            loadHospitalMarkers()
        }
    }

    // Function to load hospital markers (adjusted for Qatar)
    private func loadHospitalMarkers() {
        let hospitals = [
            (name: "Hamad General Hospital", latitude: 25.276987, longitude: 51.520008),
            (name: "Al Wakra Hospital", latitude: 25.165173, longitude: 51.603165),
            (name: "Sidra Medicine", latitude: 25.310556, longitude: 51.445278),
            (name: "Aspetar Orthopedic Hospital", latitude: 25.263056, longitude: 51.448333),
            (name: "Al Khor Hospital", latitude: 25.690000, longitude: 51.505833),
            (name: "The Cuban Hospital", latitude: 25.614444, longitude: 50.879444),
            (name: "Rumailah Hospital", latitude: 25.2885, longitude: 51.5145),
            (name: "Women's Wellness and Research Center", latitude: 25.2766, longitude: 51.5204),
            (name: "Heart Hospital", latitude: 25.2767, longitude: 51.5203),
            (name: "National Center for Cancer Care and Research (NCCCR)", latitude: 25.2768, longitude: 51.5202),
            (name: "Hazm Mebaireek General Hospital", latitude: 25.1853, longitude: 51.4408),
            (name: "Al-Ahli Hospital", latitude: 25.2753, longitude: 51.5144),
            (name: "Al Emadi Hospital", latitude: 25.2612, longitude: 51.4889),
            (name: "The View Hospital", latitude: 25.3211, longitude: 51.5200),
            (name: "Aman Hospital", latitude: 25.2841, longitude: 51.5205),
            (name: "Al Farid Hospital", latitude: 25.2800, longitude: 51.5200)
        ]

        markers = hospitals.map { hospital in
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: hospital.latitude, longitude: hospital.longitude)
            marker.title = hospital.name
            marker.snippet = "\(hospital.latitude), \(hospital.longitude)"
            return marker
        }
    }
}
