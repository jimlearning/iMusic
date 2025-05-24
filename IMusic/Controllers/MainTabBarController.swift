import UIKit

class MainTabBarController: UITabBarController {
    
    private let musicLibraryService = MusicLibraryService()
    private lazy var musicPlayerService = MusicPlayerService(musicLibrary: musicLibraryService)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
        
        print("MainTabBarController: Registering for trackChangedNotification")
        // 注册通知以更新所有 mini player views
        NotificationCenter.default.addObserver(self, selector: #selector(trackChanged), name: MusicPlayerService.trackChangedNotification, object: nil)
        
        // 确保 musicPlayerService 初始化完成并加载上次播放的音乐
        Task {
            // 给 musicPlayerService 一些时间来加载用户设置
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            await MainActor.run {
                // 手动触发一次更新，确保所有 mini player views 显示上次播放的音乐
                print("MainTabBarController: Manually triggering mini player update after delay")
                self.trackChanged()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("MainTabBarController: viewDidAppear - Posting trackChangedNotification")
        // 在应用启动后触发一次通知，确保所有 mini player views 更新
        NotificationCenter.default.post(name: MusicPlayerService.trackChangedNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func trackChanged() {
        print("MainTabBarController: trackChanged notification received")
        // 通知所有实现了 MiniPlayerUpdatable 协议的子视图控制器更新 mini player view
        viewControllers?.forEach { navController in
            if let navController = navController as? UINavigationController,
               let viewController = navController.viewControllers.first as? MiniPlayerUpdatable {
                print("MainTabBarController: Updating mini player view for \(type(of: viewController))")
                viewController.updateMiniPlayerView()
            } else if let navController = navController as? UINavigationController {
                print("MainTabBarController: Controller \(type(of: navController.viewControllers.first)) does not implement MiniPlayerUpdatable")
            }
        }
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
        libraryNav.tabBarItem = UITabBarItem(title: "音乐库", image: UIImage(systemName: "music.note"), tag: 1)
        
        // Playlists View Controller
        let playlistsVC = PlaylistsViewController()
        playlistsVC.musicLibraryService = musicLibraryService
        playlistsVC.musicPlayerService = musicPlayerService
        let playlistsNav = UINavigationController(rootViewController: playlistsVC)
        playlistsNav.tabBarItem = UITabBarItem(title: "专辑", image: UIImage(systemName: "music.note.list"), tag: 2)

        // Mine View Controller
        let mineVC = MineViewController()
        mineVC.musicLibraryService = musicLibraryService
        mineVC.musicPlayerService = musicPlayerService
        let mineNav = UINavigationController(rootViewController: mineVC)
        mineNav.tabBarItem = UITabBarItem(title: "我", image: UIImage(systemName: "person"), tag: 4)
        
        // Set the view controllers
        viewControllers = [homeNav, libraryNav, playlistsNav, mineNav]
    }
}
