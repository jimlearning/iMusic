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
        case playback
        case library
        case logout
        
        var title: String {
            switch self {
            case .playback: return "Playback"
            case .library: return "Library"
            case .logout: return "Logout"
            }
        }
    }
    
    enum PlaybackRow: Int, CaseIterable {
        case volume
        case equalizer
        case repeatMode
        case shuffle
        
        var title: String {
            switch self {
            case .volume: return "Volume"
            case .equalizer: return "Equalizer"
            case .repeatMode: return "Repeat Mode"
            case .shuffle: return "Shuffle"
            }
        }
    }
    
    enum LibraryRow: Int, CaseIterable {
        case sortBy
        case clearCache
        case recreatePlaylists
        
        var title: String {
            switch self {
            case .sortBy: return "Sort By"
            case .clearCache: return "Clear Cache"
            case .recreatePlaylists: return "Recreate All Playlists"
            }
        }
    }
    
    enum AboutRow: Int, CaseIterable {
        case version
        case feedback
        
        var title: String {
            switch self {
            case .version: return "Version"
            case .feedback: return "Send Feedback"
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSettings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMiniPlayerView()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = "Settings"
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
    
    private func showRepeatModeOptions() {
        let alertController = UIAlertController(title: "Repeat Mode", message: nil, preferredStyle: .actionSheet)
        
        let modes: [(RepeatMode, String)] = [
            (.none, "No Repeat"),
            (.all, "Repeat All"),
            (.one, "Repeat One")
        ]
        
        for (mode, title) in modes {
            alertController.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                self.settings?.repeatMode = mode
                self.musicPlayerService.repeatMode = mode
                self.saveSettings()
                self.tableView.reloadData()
            })
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    private func showSortOptions() {
        let alertController = UIAlertController(title: "Sort Library By", message: nil, preferredStyle: .actionSheet)
        
        for option in SortOption.allCases {
            alertController.addAction(UIAlertAction(title: option.rawValue, style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                self.settings?.sortOption = option
                self.saveSettings()
                self.tableView.reloadData()
            })
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    private func showEqualizerOptions() {
        let alertController = UIAlertController(title: "Equalizer Preset", message: nil, preferredStyle: .actionSheet)
        
        for preset in EqualizerPreset.allCases {
            alertController.addAction(UIAlertAction(title: preset.rawValue, style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                self.settings?.equalizerPreset = preset
                self.saveSettings()
                self.tableView.reloadData()
            })
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    private func clearCache() {
        showConfirmationAlert(
            title: "Clear Cache",
            message: "This will clear all cached data but won't delete your music files. Are you sure?",
            confirmAction: {
                // Clear cached data
                UserDefaults.standard.removeObject(forKey: "com.imusic.userSettings")
                
                self.showAlert(title: "Cache Cleared", message: "All cached data has been cleared.")
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
        title: "Recreate All Playlists",
        message: "This will recreate all default playlists based on your music library. Any custom playlists will not be affected. Continue?",
        confirmAction: {
            Task {
                // Show loading indicator
                let loadingAlert = self.showLoadingAlert(message: "Recreating playlists...")
                
                // Recreate playlists
                await DefaultPlaylistsManager.forceRecreateAllPlaylists(musicLibraryService: self.musicLibraryService)
                
                // Dismiss loading indicator
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        // Show success message
                        self.showAlert(title: "Success", message: "All playlists have been recreated successfully.")
                    }
                }
            }
        }
    )
}
    
private func logout() {
    showConfirmationAlert(
        title: "Logout",
        message: "Are you sure you want to logout?",
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .playback: return PlaybackRow.allCases.count
        case .library: return LibraryRow.allCases.count
        case .logout: return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        return sectionType.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch sectionType {
        case .playback:
            guard let rowType = PlaybackRow(rawValue: indexPath.row) else {
                return UITableViewCell()
            }
            
            switch rowType {
            case .volume:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SliderCell", for: indexPath) as! SliderTableViewCell
                cell.titleLabel.text = rowType.title
                cell.slider.value = musicPlayerService.volume
                cell.slider.addTarget(self, action: #selector(volumeChanged(_:)), for: .valueChanged)
                return cell
                
            case .equalizer:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
                cell.textLabel?.text = rowType.title
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.text = settings?.equalizerPreset.rawValue
                cell.accessoryType = .disclosureIndicator
                return cell
                
            case .repeatMode:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
                cell.textLabel?.text = rowType.title
                cell.textLabel?.textColor = .label
                
                let repeatMode = settings?.repeatMode ?? .none
                switch repeatMode {
                case .none: cell.detailTextLabel?.text = "No Repeat"
                case .all: cell.detailTextLabel?.text = "Repeat All"
                case .one: cell.detailTextLabel?.text = "Repeat One"
                }
                
                cell.accessoryType = .disclosureIndicator
                return cell
                
            case .shuffle:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchTableViewCell
                cell.titleLabel.text = rowType.title
                cell.switchControl.isOn = settings?.shuffleEnabled ?? false
                cell.switchControl.addTarget(self, action: #selector(shuffleToggled(_:)), for: .valueChanged)
                return cell
            }
            
        case .library:
            guard let rowType = LibraryRow(rawValue: indexPath.row) else {
                return UITableViewCell()
            }
            
            switch rowType {
            case .sortBy:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
                cell.textLabel?.text = rowType.title
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.text = settings?.sortOption.rawValue
                cell.accessoryType = .disclosureIndicator
                return cell
                
            case .clearCache:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
                cell.textLabel?.text = rowType.title
                cell.textLabel?.textColor = .systemRed
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
        case .playback:
            guard let rowType = PlaybackRow(rawValue: indexPath.row) else { return }
            
            switch rowType {
            case .volume:
                break // Handled by slider
                
            case .equalizer:
                showEqualizerOptions()
                
            case .repeatMode:
                showRepeatModeOptions()
                
            case .shuffle:
                break // Handled by switch
            }
            
        case .library:
            guard let rowType = LibraryRow(rawValue: indexPath.row) else { return }
            
            switch rowType {
            case .sortBy:
                showSortOptions()
                
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
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Confirm", style: .destructive) { _ in
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
