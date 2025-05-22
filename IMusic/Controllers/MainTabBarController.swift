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
        // Library View Controller
        let libraryVC = LibraryViewController()
        libraryVC.musicLibraryService = musicLibraryService
        libraryVC.musicPlayerService = musicPlayerService
        let libraryNav = UINavigationController(rootViewController: libraryVC)
        libraryNav.tabBarItem = UITabBarItem(title: "Library", image: UIImage(systemName: "music.note"), tag: 0)
        
        // Playlists View Controller
        let playlistsVC = PlaylistsViewController()
        playlistsVC.musicLibraryService = musicLibraryService
        playlistsVC.musicPlayerService = musicPlayerService
        let playlistsNav = UINavigationController(rootViewController: playlistsVC)
        playlistsNav.tabBarItem = UITabBarItem(title: "Playlists", image: UIImage(systemName: "music.note.list"), tag: 1)
        
        // Search View Controller
        let searchVC = SearchViewController()
        searchVC.musicLibraryService = musicLibraryService
        searchVC.musicPlayerService = musicPlayerService
        let searchNav = UINavigationController(rootViewController: searchVC)
        searchNav.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), tag: 2)
        
        // Settings View Controller
        let settingsVC = SettingsViewController()
        settingsVC.musicLibraryService = musicLibraryService
        settingsVC.musicPlayerService = musicPlayerService
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 3)
        
        // Set the view controllers
        viewControllers = [libraryNav, playlistsNav, searchNav, settingsNav]
    }
}
