import SwiftUI
import CoreData
import GoogleMaps

@main
struct ReliefBoxApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var locationManager = LocationManager()
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(locationManager)
                .onAppear {
                    APIManager.shared.startPolling(
                        context: persistenceController.container.viewContext
                    )
                }
                .onChange(of: scenePhase) { newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            APIManager.shared.startPolling(
                context: persistenceController.container.viewContext
            )
        case .inactive, .background:
            APIManager.shared.stopPolling()
        @unknown default: break
        }
    }
} 

// Core Data Persistent Controller
struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ReliefBox")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}

// Existing AppDelegate remains unchanged
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GMSServices.provideAPIKey("AIzaSyClu_JJMOiiZ7FqW0JO2Mm0JLKPZaNdoNQ")
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        MapHolder.shared.mapView.isHidden = true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        MapHolder.shared.mapView.isHidden = false
    }
}
