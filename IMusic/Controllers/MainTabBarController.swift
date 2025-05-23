import UIKit

class MainTabBarController: UITabBarController {
    
    private let musicLibraryService = MusicLibraryService()
    private lazy var musicPlayerService = MusicPlayerService(musicLibrary: musicLibraryService)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
    }
    
    private func setupTabBar() {
        tabBar.tintColor = .appPrimary
        tabBar.barTintColor = .appBackground
    }
    
    private func setupViewControllers() {
        // Home View Controller
        let homeVC = HomeViewController()
        homeVC.musicLibraryService = musicLibraryService
        homeVC.musicPlayerService = musicPlayerService
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)
        
        // Library View Controller
        let libraryVC = LibraryViewController()
        libraryVC.musicLibraryService = musicLibraryService
        libraryVC.musicPlayerService = musicPlayerService
        let libraryNav = UINavigationController(rootViewController: libraryVC)
        libraryNav.tabBarItem = UITabBarItem(title: "Library", image: UIImage(systemName: "music.note"), tag: 1)
        
        // Playlists View Controller
        let playlistsVC = PlaylistsViewController()
        playlistsVC.musicLibraryService = musicLibraryService
        playlistsVC.musicPlayerService = musicPlayerService
        let playlistsNav = UINavigationController(rootViewController: playlistsVC)
        playlistsNav.tabBarItem = UITabBarItem(title: "Playlists", image: UIImage(systemName: "music.note.list"), tag: 2)
        
        // Search View Controller
        let searchVC = SearchViewController()
        searchVC.musicLibraryService = musicLibraryService
        searchVC.musicPlayerService = musicPlayerService
        let searchNav = UINavigationController(rootViewController: searchVC)
        searchNav.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), tag: 3)
        
        // Settings View Controller
        let settingsVC = SettingsViewController()
        settingsVC.musicLibraryService = musicLibraryService
        settingsVC.musicPlayerService = musicPlayerService
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 4)
        
        // Set the view controllers
        viewControllers = [homeNav, libraryNav, playlistsNav, searchNav, settingsNav]
    }
}
