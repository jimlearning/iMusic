import UIKit

class SettingsViewController: UIViewController, MiniPlayerUpdatable {
    
    // MARK: - Properties
    var musicLibraryService: MusicLibraryService!
    var musicPlayerService: MusicPlayerService!
    
    private var settings: UserSettings?
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: "SwitchCell")
        tableView.register(SliderTableViewCell.self, forCellReuseIdentifier: "SliderCell")
        return tableView
    }()
    
    private lazy var miniPlayerView: MiniPlayerView = {
        let view = MiniPlayerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        view.isHidden = true
        return view
    }()
    
    // MARK: - Section and Row Types
    
    enum Section: Int, CaseIterable {
        case appearance
        case library
        case logout
        
        var title: String {
            switch self {
            case .appearance: return "外观"
            case .library: return "曲库"
            case .logout: return "退出登录"
            }
        }
    }
    
    enum AppearanceRow: Int, CaseIterable {
        case theme
        
        var title: String {
            switch self {
            case .theme: return "主题"
            }
        }
    }
    
    enum LibraryRow: Int, CaseIterable {
        case clearCache
        case recreatePlaylists
        
        var title: String {
            switch self {
            case .clearCache: return "清除缓存"
            case .recreatePlaylists: return "重置所有专辑"
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadSettings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMiniPlayerView()
    }
    
    // MARK: - UI Setup

    private func setupNavigationBar() {
        title = "设置"
        
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func setupUI() {
        title = "设置"
        view.backgroundColor = .appBackground
        
        view.addSubview(tableView)
        view.addSubview(miniPlayerView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: miniPlayerView.topAnchor),
            
            miniPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            miniPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            miniPlayerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            miniPlayerView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func updateMiniPlayerView() {
        if let currentItem = musicPlayerService.currentItem {
            miniPlayerView.configure(with: currentItem, playbackState: musicPlayerService.playbackState)
            miniPlayerView.isHidden = false
        } else {
            miniPlayerView.isHidden = true
        }
    }
    
    // MARK: - Data Loading
    
    private func loadSettings() {
        Task {
            do {
                settings = try await musicLibraryService.dataProvider.getUserSettings()
                
                await MainActor.run {
                    tableView.reloadData()
                }
            } catch {
                print("Failed to load settings: \(error)")
                settings = UserSettings()
            }
        }
    }
    
    private func saveSettings() {
        guard let settings = settings else { return }
        
        Task {
            do {
                try await musicLibraryService.dataProvider.saveUserSettings(settings)
            } catch {
                print("Failed to save settings: \(error)")
            }
        }
    }
    
    // MARK: - Actions
    
    private func showThemeOptions() {
        let alertController = UIAlertController(title: "主题", message: nil, preferredStyle: .actionSheet)
        
        for themeMode in ThemeMode.allCases {
            alertController.addAction(UIAlertAction(title: themeMode.displayName, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.settings?.themeMode = themeMode
                self.saveSettings()
                self.applyTheme(themeMode)
                self.tableView.reloadData()
            })
        }
        
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alertController, animated: true)
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
    
    private func clearCache() {
        showConfirmationAlert(
            title: "清除缓存",
            message: "这将清除所有缓存数据，但不会删除您的音乐文件。你确定吗？",
            confirmAction: {
                // Clear cached data
                UserDefaults.standard.removeObject(forKey: "com.imusic.userSettings")
                
                self.showAlert(title: "缓存已清除", message: "所有缓存数据均已清除。")
                self.loadSettings()
            }
        )
    
    NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        tableView.bottomAnchor.constraint(equalTo: miniPlayerView.topAnchor),
        
        miniPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        miniPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        miniPlayerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        miniPlayerView.heightAnchor.constraint(equalToConstant: 60)
    ])
}
    
    private func recreatePlaylists() {
        showConfirmationAlert(
            title: "重置所有专辑",
            message: "这将根据您的音乐库重新创建所有默认播放列表。自定义的播放列表将被删除。要继续吗？",
            confirmAction: {
                Task {
                    // Show loading indicator
                    let loadingAlert = self.showLoadingAlert(message: "重新创建播放列表...")
                    
                    // Recreate playlists
                    await DefaultPlaylistsManager.forceRecreateAllPlaylists(musicLibraryService: self.musicLibraryService)
                    
                    // Dismiss loading indicator
                    await MainActor.run {
                        loadingAlert.dismiss(animated: true) {
                            // Show success message
                            self.showAlert(title: "操作成功", message: "已成功重新创建所有播放列表。")
                        }
                    }
                }
            }
        )
    }
        
    private func logout() {
        showConfirmationAlert(
            title: "退出登录",
            message: "确定要退出登录吗？",
            confirmAction: {
                // Stop music playback
                self.musicPlayerService.stop()
                
                // Clear user login status
                UserDefaults.standard.set(false, forKey: "com.imusic.userLoggedIn")
                
                // Reset music preferences if needed
                // UserDefaults.standard.set(false, forKey: "hasCompletedMusicPreferences")
                
                // Present login screen
                let loginVC = LoginViewController()
                loginVC.modalPresentationStyle = .fullScreen
                self.present(loginVC, animated: true) {
                    // Clear navigation stack
                    self.navigationController?.viewControllers = []
                }
            }
        )
    }
        
    private func showNowPlayingView(for item: MusicItem) {
        let nowPlayingVC = NowPlayingViewController()
        nowPlayingVC.musicPlayerService = musicPlayerService
        nowPlayingVC.musicLibraryService = musicLibraryService
        nowPlayingVC.modalPresentationStyle = .fullScreen
        present(nowPlayingVC, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .appearance:
            return AppearanceRow.allCases.count
        case .library:
            return LibraryRow.allCases.count
        case .logout:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch sectionType {
        case .appearance:
            guard let rowType = AppearanceRow(rawValue: indexPath.row) else {
                return UITableViewCell()
            }
            
            switch rowType {
            case .theme:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
                cell.textLabel?.text = rowType.title
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.text = settings?.themeMode.displayName ?? "跟随系统"
                cell.accessoryType = .disclosureIndicator
                return cell
            }
            
        case .library:
            guard let rowType = LibraryRow(rawValue: indexPath.row) else {
                return UITableViewCell()
            }
            
            switch rowType {
            case .clearCache:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
                cell.textLabel?.text = rowType.title
                cell.textLabel?.textColor = .systemBlue
                return cell
                
            case .recreatePlaylists:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
                cell.textLabel?.text = rowType.title
                cell.textLabel?.textColor = .systemBlue
                return cell
            }
            
        case .logout:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
            cell.textLabel?.text = sectionType.title
            cell.textLabel?.textColor = .systemRed
            cell.accessoryType = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let sectionType = Section(rawValue: indexPath.section) else { return }
        
        switch sectionType {
        case .appearance:
            guard let rowType = AppearanceRow(rawValue: indexPath.row) else { return }
            
            switch rowType {
            case .theme:
                showThemeOptions()
            }
            
        case .library:
            guard let rowType = LibraryRow(rawValue: indexPath.row) else { return }
            
            switch rowType {
            case .clearCache:
                clearCache()
                
            case .recreatePlaylists:
                recreatePlaylists()
            }
            
        case .logout:
            logout()
        }
    }
    
    // MARK: - Control Actions
    
    @objc func volumeChanged(_ slider: UISlider) {
        musicPlayerService.setVolume(slider.value)
        settings?.volume = slider.value
        saveSettings()
    }
    
    @objc func shuffleToggled(_ switchControl: UISwitch) {
        settings?.shuffleEnabled = switchControl.isOn
        musicPlayerService.toggleShuffle()
        saveSettings()
    }
}

// MARK: - Helper Methods
extension SettingsViewController {
    private func showConfirmationAlert(title: String, message: String, confirmAction: @escaping () -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        alertController.addAction(UIAlertAction(title: "确认", style: .destructive) { _ in
            confirmAction()
        })
        
        present(alertController, animated: true)
    }
    
    private func showLoadingAlert(message: String) -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        
        alertController.view.addSubview(loadingIndicator)
        present(alertController, animated: true)
        
        return alertController
    }
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
}

// MARK: - MiniPlayerViewDelegate
extension SettingsViewController: MiniPlayerViewDelegate {
    func miniPlayerViewDidTapPlayPause(_ miniPlayerView: MiniPlayerView) {
        musicPlayerService.togglePlayPause()
        updateMiniPlayerView()
    }
    
    func miniPlayerViewDidTapView(_ miniPlayerView: MiniPlayerView) {
        if let currentItem = musicPlayerService.currentItem {
            showNowPlayingView(for: currentItem)
        }
    }
}
