//
//  SceneDelegate.swift
//  IMusic
//
//  Created by Jim Learning on 2025/5/22.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Create window with the scene
        window = UIWindow(windowScene: windowScene)
        
        // Check if user is already logged in
        if isUserLoggedIn() {
            // User is logged in, go directly to main interface with TabBar
            let mainTabBarController = MainTabBarController()
            window?.rootViewController = mainTabBarController
        } else {
            // User is not logged in, show login screen
            window?.rootViewController = LoginViewController()
        }
        
        window?.makeKeyAndVisible()
    }
    
    // Helper method to check if user is logged in
    private func isUserLoggedIn() -> Bool {
        // Check UserDefaults for login status
        return UserDefaults.standard.bool(forKey: "com.imusic.userLoggedIn")
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}

