//
//  ProfileView.swift
//  ReliefBox
//
//  Created by Diyorbek Ibragimov on 31/01/2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var selectedLanguage: String = "English" // Default language
    @State private var emergencyContacts: [String] = ["", "", ""] // Placeholder for 3 contacts
    @State private var selectedCountry: String = "Qatar" // Default country

    var body: some View {
        NavigationView {
            List {
                // Language Selection Section
                Section(header: Text("Language").font(.headline)) {
                    Picker("Choose Language", selection: $selectedLanguage) {
                        Text("English").tag("English")
                        Text("Arabic").tag("Arabic")
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                // Emergency Contacts Section
                Section(header: Text("Emergency Contacts").font(.headline)) {
                    ForEach(0..<3, id: \.self) { index in
                        HStack {
                            Text("Contact \(index + 1)")
                            Spacer()
                            TextField("Enter number", text: Binding(
                                get: { emergencyContacts[index] },
                                set: { emergencyContacts[index] = $0 }
                            ))
                            .keyboardType(.numberPad) // Use number pad for input
                            .multilineTextAlignment(.trailing)
                        }
                    }

                    // Save Contacts Button
                    Button(action: saveContacts) {
                        HStack {
                            Spacer()
                            Text("Save Contacts")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                            Spacer()
                        }
                    }
                }

                // Location Selection Section
                Section(header: Text("Location").font(.headline)) {
                    HStack {
                        Text("Country")
                        Spacer()
                        NavigationLink(destination: CountrySelectionView(selectedCountry: $selectedCountry)) {
                            Text(selectedCountry)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle()) // Matches the style of the attached image
            .toolbar {
                ToolbarItem(placement: .principal) { // Custom navigation title
                    Text("Profile Settings")
                        .font(.title)
                        .bold()
                }
            }
        }
    }

    // Save Contacts Action
    private func saveContacts() {
        print("Contacts saved:", emergencyContacts)
        // Clear input fields after saving
        emergencyContacts = ["", "", ""]
    }
}

// Country Selection View
struct CountrySelectionView: View {
    @Binding var selectedCountry: String
    let countries = ["Qatar", "Palestine", "Syria", "Lebanon", "Turkey", "Ukraine"]

    var body: some View {
        List(countries, id: \.self) { country in
            Button(action: {
                selectedCountry = country
            }) {
                HStack {
                    Text(country)
                    if selectedCountry == country {
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle("Select Country")
    }
}
