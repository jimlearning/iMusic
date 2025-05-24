import UIKit

class MineViewController: UIViewController, MiniPlayerUpdatable {
    
    // MARK: - Properties
    var musicLibraryService: MusicLibraryService!
    var musicPlayerService: MusicPlayerService!
    
    private var favorites: [MusicItem] = []
    
    // MARK: - UI Components
    private lazy var headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.iconDefaultArtwork
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 70 // Half of the width/height
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MenuCell")
        tableView.backgroundColor = .appBackground
        tableView.separatorStyle = .singleLine
        return tableView
    }()
    
    private lazy var miniPlayerView: MiniPlayerView = {
        let view = MiniPlayerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        
        // Register for notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMiniPlayerView),
            name: MusicPlayerService.trackChangedNotification,
            object: nil
        )
        
        // Fix initial scroll position
        tableView.contentInsetAdjustmentBehavior = .never
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFavorites()
        updateMiniPlayerView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Reset scroll position to top with the header fully visible
        tableView.setContentOffset(.zero, animated: false)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .appBackground
        
        // Add subviews
        view.addSubview(tableView)
        view.addSubview(miniPlayerView)
        
        // Setup constraints
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
        
        setupHeaderView()
    }
    
    private func setupHeaderView() {
        // Create header view with larger height
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 250))
        headerView.backgroundColor = .appBackground
        
        // Add profile image with larger size
        headerView.addSubview(profileImageView)
        
        // Position profile image
        profileImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 140).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 140).isActive = true
        
        // Set as table header view
        tableView.tableHeaderView = headerView
        
        // Adjust content inset to account for the header
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    private func setupNavigationBar() {
        title = "我"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Add settings button
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsButtonTapped)
        )
        navigationItem.rightBarButtonItem = settingsButton
    }
    
    // MARK: - Data Loading
    private func loadFavorites() {
        Task {
            do {
                let favorites = try await musicLibraryService.getFavorites()
                await MainActor.run {
                    self.favorites = favorites
                    self.tableView.reloadData()
                }
            } catch {
                print("Error loading favorites: \(error)")
            }
        }
    }
    
    // MARK: - Actions
    @objc private func settingsButtonTapped() {
        let settingsVC = SettingsViewController()
        settingsVC.musicLibraryService = musicLibraryService
        settingsVC.musicPlayerService = musicPlayerService
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    // MARK: - MiniPlayerUpdatable
    @objc func updateMiniPlayerView() {
        guard let currentItem = musicPlayerService.currentItem else {
            miniPlayerView.isHidden = true
            return
        }
        
        miniPlayerView.isHidden = false
        miniPlayerView.configure(with: currentItem, playbackState: musicPlayerService.playbackState)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension MineViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3 // Favorites, Playlists, and Library options
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .appBackground
        
        // Configure cell based on row (compatible with iOS 13)
        switch indexPath.row {
        case 0: // Favorites
            cell.textLabel?.text = "收藏"
            cell.imageView?.image = UIImage(systemName: "heart.fill")
            cell.imageView?.tintColor = .systemRed
            
        case 1: // Playlists
            cell.textLabel?.text = "专辑"
            cell.imageView?.image = UIImage(systemName: "music.note.list")
            cell.imageView?.tintColor = .systemBlue
            
        case 2: // Library
            cell.textLabel?.text = "音乐库"
            cell.imageView?.image = UIImage(systemName: "music.note")
            cell.imageView?.tintColor = .systemGreen
            
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0: // Favorites
            // Navigate to favorites playlist
            let playlistVC = PlaylistDetailViewController()
            playlistVC.musicLibraryService = musicLibraryService
            playlistVC.musicPlayerService = musicPlayerService
            
            // Create a virtual playlist for favorites
            let favoritesPlaylist = PlaylistItem(name: "收藏", musicItems: favorites)
            playlistVC.playlist = favoritesPlaylist
            playlistVC.isFavoritesPlaylist = true
            
            navigationController?.pushViewController(playlistVC, animated: true)
            
        case 1: // Playlists
            // Navigate to playlists view controller
            let playlistsVC = PlaylistsViewController()
            playlistsVC.musicLibraryService = musicLibraryService
            playlistsVC.musicPlayerService = musicPlayerService
            navigationController?.pushViewController(playlistsVC, animated: true)
            
        case 2: // Library
            // Navigate to library view controller
            let libraryVC = LibraryViewController()
            libraryVC.musicLibraryService = musicLibraryService
            libraryVC.musicPlayerService = musicPlayerService
            navigationController?.pushViewController(libraryVC, animated: true)
            
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - MiniPlayerViewDelegate
extension MineViewController: MiniPlayerViewDelegate {
    
    func miniPlayerViewDidTapView(_ miniPlayerView: MiniPlayerView) {
        let nowPlayingVC = NowPlayingViewController()
        nowPlayingVC.musicLibraryService = musicLibraryService
        nowPlayingVC.musicPlayerService = musicPlayerService
        nowPlayingVC.modalPresentationStyle = .fullScreen
        present(nowPlayingVC, animated: true)
    }
    
    func miniPlayerViewDidTapPlayPause(_ miniPlayerView: MiniPlayerView) {
        musicPlayerService.togglePlayPause()
        updateMiniPlayerView()
    }
}

// MARK: - UIScrollViewDelegate
extension MineViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let headerView = tableView.tableHeaderView
        
        // Calculate the stretch effect
        let offsetY = scrollView.contentOffset.y
        
        if offsetY < 0 {
            let stretchFactor = abs(offsetY) / 100
            let scale = 1.0 + min(stretchFactor, 0.6) // Increased max scale
            
            // Apply scaling to profile image
            profileImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            // Adjust header height
            var frame = headerView?.frame ?? .zero
            frame.size.height = 250 + abs(offsetY) // Increased base height
            headerView?.frame = frame
            
            // Force layout update
            tableView.tableHeaderView = headerView
        } else {
            // Reset when scrolling down
            profileImageView.transform = .identity
        }
    }
}
