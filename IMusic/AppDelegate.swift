//
//  AppDelegate.swift
//  IMusic
//
//  Created by Jim Learning on 2025/5/22.
//

import UIKit
import CoreData
import AVFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Setup audio session for background playback
        setupAudioSession()
        
        // Setup appearance
        setupAppearance()
        
        return true
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupAppearance() {
        // Load theme settings
        Task {
            do {
                let dataProvider = LocalDataProvider()
                let userSettings = try await dataProvider.getUserSettings()
                await MainActor.run {
                    applyTheme(userSettings.themeMode)
                }
            } catch {
                print("Error loading theme settings: \(error)")
            }
        }
        
        // Setup navigation bar appearance
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .appBackground
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        
        // Setup UISearchBar appearance - localize the cancel button
        UISearchBar.setupAppearance()
    }
    
    private func applyTheme(_ themeMode: ThemeMode) {
        let window = UIApplication.shared.windows.first
        
        switch themeMode {
        case .light:
            window?.overrideUserInterfaceStyle = .light
        case .dark:
            window?.overrideUserInterfaceStyle = .dark
        case .system:
            window?.overrideUserInterfaceStyle = .unspecified
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "IMusic")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Core Data error: \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Core Data save error: \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
