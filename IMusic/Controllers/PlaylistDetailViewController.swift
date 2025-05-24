import UIKit

class PlaylistDetailViewController: UIViewController, MiniPlayerUpdatable {
    
    // MARK: - Properties
    var musicLibraryService: MusicLibraryService!
    var musicPlayerService: MusicPlayerService!
    var playlist: PlaylistItem!
    var isFavoritesPlaylist: Bool = false
    
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
        label.text = "您的收藏是空的"
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
            headerView.heightAnchor.constraint(equalToConstant: 190),
            
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
        
        // Hide add button for favorites playlist
        navigationItem.rightBarButtonItem?.isEnabled = !isFavoritesPlaylist
    }
    
    private func refreshPlaylist() {
        Task {
            do {
                if isFavoritesPlaylist {
                    let favorites = try await musicLibraryService.getFavorites()
                    await MainActor.run {
                        self.musicItems = favorites
                        // Update the virtual playlist
                        self.playlist = PlaylistItem(name: "收藏", musicItems: favorites)
                        self.updateUI()
                        self.tableView.reloadData()
                        self.updateEmptyState()
                    }
                } else if let updatedPlaylist = musicLibraryService.playlists.first(where: { $0.id == playlist.id }) {
                    await MainActor.run {
                        self.playlist = updatedPlaylist
                        self.musicItems = updatedPlaylist.musicItems
                        self.updateUI()
                        self.tableView.reloadData()
                        self.updateEmptyState()
                    }
                }
            } catch {
                print("Error refreshing playlist: \(error)")
            }
        }
    }
    
    private func updateEmptyState() {
        let isEmpty = musicItems.isEmpty
        emptyStateLabel.isHidden = !isEmpty
    }
    
    func updateMiniPlayerView() {
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
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = musicItems[indexPath.row]
        
        let favoriteAction = UIContextualAction(style: .normal, title: item.isFavorite ? "取消收藏" : "收藏") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            Task {
                do {
                    let updatedItem = try await self.musicLibraryService.toggleFavorite(item)
                    await MainActor.run {
                        // Update the item in the list
                        if let index = self.musicItems.firstIndex(where: { $0.id == updatedItem.id }) {
                            self.musicItems[index] = updatedItem
                        }
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                        
                        // If this is the favorites playlist and we unfavorited an item, refresh the playlist
                        if self.isFavoritesPlaylist && !updatedItem.isFavorite {
                            self.refreshPlaylist()
                        }
                    }
                } catch {
                    print("Error toggling favorite: \(error)")
                }
            }
            
            completion(true)
        }
        
        favoriteAction.backgroundColor = item.isFavorite ? .systemGray : .systemRed
        favoriteAction.image = UIImage(systemName: item.isFavorite ? "heart.slash.fill" : "heart.fill")
        
        return UISwipeActionsConfiguration(actions: [favoriteAction])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        musicPlayerService.setQueue(musicItems, startIndex: indexPath.row)
        musicPlayerService.play()
        
        updateMiniPlayerView()
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = self.musicItems[indexPath.row]
        
        if isFavoritesPlaylist {
            let unfavoriteAction = UIContextualAction(style: .destructive, title: "取消收藏") { [weak self] (_, _, completion) in
                guard let self = self else { return }
                
                Task {
                    do {
                        _ = try await self.musicLibraryService.toggleFavorite(item)
                        self.refreshPlaylist()
                    } catch {
                        await MainActor.run {
                            self.showAlert(title: "取消收藏失败", message: "取消收藏失败: \(error.localizedDescription)")
                        }
                    }
                }
                
                completion(true)
            }
            unfavoriteAction.backgroundColor = .systemRed
            return UISwipeActionsConfiguration(actions: [unfavoriteAction])
        } else {
            let removeAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] (_, _, completion) in
                guard let self = self else { return }
                
                Task {
                    do {
                        try await self.musicLibraryService.removeFromPlaylist(item, playlist: self.playlist)
                        self.refreshPlaylist()
                    } catch {
                        await MainActor.run {
                            self.showAlert(title: "删除专辑失败", message: "删除专辑失败: \(error.localizedDescription)")
                        }
                    }
                }
                
                completion(true)
            }
            
            return UISwipeActionsConfiguration(actions: [removeAction])
        }
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
                    showAlert(title: "添加失败", message: "添加到专辑失败: \(error.localizedDescription)")
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
