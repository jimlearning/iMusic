import UIKit

class PlaylistDetailViewController: UIViewController {
    
    // MARK: - Properties
    var musicLibraryService: MusicLibraryService!
    var musicPlayerService: MusicPlayerService!
    var playlist: PlaylistItem!
    
    private var musicItems: [MusicItem] = []
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MusicItemCell.self, forCellReuseIdentifier: "MusicItemCell")
        tableView.rowHeight = 72
        return tableView
    }()
    
    private lazy var headerView: PlaylistHeaderView = {
        let view = PlaylistHeaderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var miniPlayerView: MiniPlayerView = {
        let view = MiniPlayerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        view.isHidden = true
        return view
    }()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "This playlist is empty"
        label.textColor = .appSubtext
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.isHidden = true
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshPlaylist()
        updateMiniPlayerView()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .appBackground
        
        view.addSubview(headerView)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(miniPlayerView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 180),
            
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: miniPlayerView.topAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: tableView.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: -20),
            
            miniPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            miniPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            miniPlayerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            miniPlayerView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Setup navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMusicTapped))
        
        // Setup header view actions
        headerView.playAllButton.addTarget(self, action: #selector(playAllTapped), for: .touchUpInside)
        headerView.shuffleButton.addTarget(self, action: #selector(shuffleTapped), for: .touchUpInside)
    }
    
    private func updateUI() {
        title = playlist.name
        headerView.configure(with: playlist)
        updateEmptyState()
    }
    
    private func refreshPlaylist() {
        if let updatedPlaylist = musicLibraryService.playlists.first(where: { $0.id == playlist.id }) {
            playlist = updatedPlaylist
            musicItems = playlist.musicItems
            updateUI()
            tableView.reloadData()
        }
    }
    
    private func updateEmptyState() {
        let isEmpty = musicItems.isEmpty
        emptyStateLabel.isHidden = !isEmpty
    }
    
    private func updateMiniPlayerView() {
        if let currentItem = musicPlayerService.currentItem {
            miniPlayerView.configure(with: currentItem, playbackState: musicPlayerService.playbackState)
            miniPlayerView.isHidden = false
        } else {
            miniPlayerView.isHidden = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func addMusicTapped() {
        let musicPickerVC = MusicPickerViewController()
        musicPickerVC.musicLibraryService = musicLibraryService
        musicPickerVC.delegate = self
        musicPickerVC.selectedPlaylist = playlist
        navigationController?.pushViewController(musicPickerVC, animated: true)
    }
    
    @objc private func playAllTapped() {
        guard !musicItems.isEmpty else { return }
        
        musicPlayerService.setQueue(musicItems)
        musicPlayerService.play()
        updateMiniPlayerView()
    }
    
    @objc private func shuffleTapped() {
        guard !musicItems.isEmpty else { return }
        
        var shuffledItems = musicItems
        shuffledItems.shuffle()
        
        musicPlayerService.setQueue(shuffledItems)
        musicPlayerService.play()
        updateMiniPlayerView()
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
extension PlaylistDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musicItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MusicItemCell", for: indexPath) as? MusicItemCell else {
            return UITableViewCell()
        }
        
        let item = musicItems[indexPath.row]
        cell.configure(with: item)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        musicPlayerService.setQueue(musicItems, startIndex: indexPath.row)
        musicPlayerService.play()
        
        updateMiniPlayerView()
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let removeAction = UIContextualAction(style: .destructive, title: "Remove") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            let item = self.musicItems[indexPath.row]
            
            Task {
                do {
                    try await self.musicLibraryService.removeFromPlaylist(item, playlist: self.playlist)
                    self.refreshPlaylist()
                } catch {
                    await MainActor.run {
                        self.showAlert(title: "Error", message: "Failed to remove from playlist: \(error.localizedDescription)")
                    }
                }
            }
            
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [removeAction])
    }
}

// MARK: - MusicPickerViewControllerDelegate
extension PlaylistDetailViewController: MusicPickerViewControllerDelegate {
    func musicPickerDidSelectItems(_ items: [MusicItem]) {
        Task {
            do {
                for item in items {
                    try await musicLibraryService.addToPlaylist(item, playlist: playlist)
                }
                
                refreshPlaylist()
            } catch {
                await MainActor.run {
                    showAlert(title: "Error", message: "Failed to add to playlist: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - MiniPlayerViewDelegate
extension PlaylistDetailViewController: MiniPlayerViewDelegate {
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
