import UIKit

class PlaylistsViewController: UIViewController, MiniPlayerUpdatable {
    
    // MARK: - Properties
    var musicLibraryService: MusicLibraryService!
    var musicPlayerService: MusicPlayerService!
    
    private var playlists: [PlaylistItem] = []
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PlaylistCell.self, forCellReuseIdentifier: "PlaylistCell")
        tableView.rowHeight = 72
        return tableView
    }()
    
    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        
        let imageView = UIImageView(image: UIImage.iconDefaultAlbumSmall)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .appSubtext
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "没有专辑"
        label.textColor = .appSubtext
        label.font = UIFont.systemFont(ofSize: 18)
        
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("创建专辑", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(createPlaylistTapped), for: .touchUpInside)
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(button)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 80),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        
        return view
    }()
    
    private lazy var miniPlayerView: MiniPlayerView = {
        let view = MiniPlayerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        view.isHidden = true
        return view
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPlaylists()
        updateMiniPlayerView()
    }
    
    // MARK: - UI Setup
        
    private func setupNavigationBar() {
        title = "专辑"
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createPlaylistTapped))
        navigationItem.rightBarButtonItem = addButton
    }
    
    private func setupUI() {
        view.backgroundColor = .appBackground
        
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(miniPlayerView)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: miniPlayerView.topAnchor),
            
            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: miniPlayerView.topAnchor),
            
            miniPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            miniPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            miniPlayerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            miniPlayerView.heightAnchor.constraint(equalToConstant: 60),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadPlaylists() {
        activityIndicator.startAnimating()
        
        Task {
            await musicLibraryService.loadData()
            
            await MainActor.run {
                self.activityIndicator.stopAnimating()
                self.playlists = musicLibraryService.playlists
                self.tableView.reloadData()
                self.updateEmptyState()
            }
        }
    }
    
    private func updateEmptyState() {
        let isEmpty = playlists.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
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
    
    @objc private func createPlaylistTapped() {
        self.showTextInputAlert(
            title: "创建专辑",
            message: "请输入新的专辑名称",
            placeholder: "专辑名称"
        ) { [weak self] name in
            guard let self = self else { return }
            
            Task {
                do {
                    let _ = try await self.musicLibraryService.createPlaylist(name: name)
                    
                    await MainActor.run {
                        self.playlists = self.musicLibraryService.playlists
                        self.tableView.reloadData()
                        self.updateEmptyState()
                    }
                } catch {
                    await MainActor.run {
                        self.showAlert(title: "错误", message: "创建专辑失败: \(error.localizedDescription)")
                    }
                }
            }
        }
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
extension PlaylistsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath) as? PlaylistCell else {
            return UITableViewCell()
        }
        
        let playlist = playlists[indexPath.row]
        cell.configure(with: playlist)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let playlist = playlists[indexPath.row]
        let playlistDetailVC = PlaylistDetailViewController()
        playlistDetailVC.musicLibraryService = musicLibraryService
        playlistDetailVC.musicPlayerService = musicPlayerService
        playlistDetailVC.playlist = playlist
        navigationController?.pushViewController(playlistDetailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let playlist = playlists[indexPath.row]
        
        // For playlists, we'll add a "Play" action that starts playing the playlist
        let playAction = UIContextualAction(style: .normal, title: "播放") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            if !playlist.musicItems.isEmpty {
                self.musicPlayerService.setQueue(playlist.musicItems)
                self.musicPlayerService.play()
            }
            
            completion(true)
        }
        
        playAction.backgroundColor = .systemGreen
        playAction.image = UIImage(systemName: "play.fill")
        
        return UISwipeActionsConfiguration(actions: [playAction])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            let playlist = self.playlists[indexPath.row]
            
            self.showConfirmationAlert(
                title: "删除专辑",
                message: "确定要删除 \(playlist.name)?",
                confirmAction: {
                    Task {
                        do {
                            try await self.musicLibraryService.deletePlaylist(playlist)
                            
                            await MainActor.run {
                                self.playlists = self.musicLibraryService.playlists
                                self.tableView.reloadData()
                                self.updateEmptyState()
                            }
                        } catch {
                            await MainActor.run {
                                self.showAlert(title: "删除专辑失败", message: "删除专辑失败: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            )
            
            completion(true)
        }
        
        let renameAction = UIContextualAction(style: .normal, title: "重命名") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            let playlist = self.playlists[indexPath.row]
            
            self.showTextInputAlert(
                title: "重命名专辑",
                message: "请输入新的专辑名称",
                placeholder: "专辑名称"
            ) { newName in
                Task {
                    do {
                        try await self.musicLibraryService.renamePlaylist(playlist, newName: newName)
                        
                        await MainActor.run {
                            self.playlists = self.musicLibraryService.playlists
                            self.tableView.reloadData()
                        }
                    } catch {
                        await MainActor.run {
                            self.showAlert(title: "错误", message: "重命名专辑失败: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            completion(true)
        }
        
        renameAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
    }
}

// MARK: - MiniPlayerViewDelegate
extension PlaylistsViewController: MiniPlayerViewDelegate {
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
