# ReliefBox

ReliefBox is an AI-powered mobile app designed to deliver real-time, localized first aid guidance during emergencies. Built for iOS using SwiftUI and Core Data (see [`ReliefBoxApp.swift`](ReliefBox/ReliefBoxApp.swift)), the app aims to empower individuals—especially those in war-torn or resource-limited areas—with step-by-step first aid assistance when professional help is not immediately available.

## Overview

During crises, the lack of accessible first aid resources can lead to unnecessary complications or even death. For example, studies indicate that up to 60% of fatalities could be prevented if bystanders had basic first aid knowledge. Our solution targets the most vulnerable segments of society, including those living in areas affected by war or natural disasters, by offering an intuitive, AI-guided platform.

## Problem Statement

Many adults, even in developed countries, feel unprepared to offer effective first aid. In regions like Gaza and Syria, decades of conflict have reduced access to medical education and infrastructure. ReliefBox addresses this critical need by ensuring that:
- Emergency instructions are clear, concise, and actionable.
- Guidance is tailored to the user’s local context and available resources.
- The app can operate even in environments with limited healthcare infrastructure.

## Our Solution

ReliefBox leverages a locally running AI model (configured in [`ReliefBox/LLM/Config.swift`](ReliefBox/LLM/Config.swift)) to:
- Analyze user inputs (text or images) regarding an emergency situation.
- Provide customized first aid recommendations based on the injury and available local resources.
- Offer real-time updates to significantly improve pre-hospital care in crisis situations.

## Key Features

- **Intuitive Interface:** A simple main screen for quick user interaction.
- **AI-Powered Guidance:** Real-time first aid recommendations adapted to the user's environment.
- **Localized Approach:** Instructions consider local resource constraints transforming generic first aid advice into practical actions.
- **Integration with Maps:** Uses Google Maps for navigation to nearby hospitals or medical facilities (see [`MedPointsView.swift`](ReliefBox/View/MedPointsView.swift)).
- **Robust Architecture:** Integrates Core Data, location services, and third-party libraries (configured in [`ReliefBox.xcodeproj/project.pbxproj`](ReliefBox.xcodeproj/project.pbxproj)) for a seamless user experience.

## Hackathon Impact

ReliefBox is being developed as part of a hackathon initiative focused on addressing the urgent need for accessible first aid guidance in crisis scenarios. Our goal is to:
- Reduce injury complications and improve outcomes in emergency care.
- Enable communities in war zones, such as Palestine, to act decisively during emergencies.
- Collaborate with local NGOs, health care providers, and government bodies to drive widespread adoption and provide essential training.

## Installation and Running

1. **Clone the Repository:**
   ```sh
   git clone https://github.com/diyorbekibragimov/ReliefBox.git