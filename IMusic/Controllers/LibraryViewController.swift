import UIKit

class LibraryViewController: UIViewController, MiniPlayerUpdatable {
    
    // MARK: - Properties
    var musicLibraryService: MusicLibraryService!
    var musicPlayerService: MusicPlayerService!
    
    private var musicItems: [MusicItem] = []
    private var filteredMusicItems: [MusicItem] = []
    private var isFiltering: Bool = false
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MusicItemCell.self, forCellReuseIdentifier: "MusicItemCell")
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
        
        let imageView = UIImageView(image: UIImage(systemName: "music.note.list"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .appSubtext
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "您的音乐库是空的"
        label.textColor = .appSubtext
        label.font = UIFont.systemFont(ofSize: 18)
        
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("导入音乐", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(importMusicTapped), for: .touchUpInside)
        
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
        loadMusicLibrary()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMiniPlayerView()
    }
    
    // MARK: - UI Setup

    private func setupNavigationBar() {
        title = "曲库"
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let importButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importMusicTapped))
        let sortButton = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(sortButtonTapped))
        
        navigationItem.rightBarButtonItems = [importButton, sortButton]
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "搜索音乐"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
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
    
    private func loadMusicLibrary() {
        activityIndicator.startAnimating()
        
        Task {
            await musicLibraryService.loadData()
            
            await MainActor.run {
                self.activityIndicator.stopAnimating()
                self.musicItems = musicLibraryService.musicItems
                self.tableView.reloadData()
                self.updateEmptyState()
            }
        }
    }
    
    private func updateEmptyState() {
        let isEmpty = musicItems.isEmpty
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
    
    @objc private func importMusicTapped() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.audio"], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true)
    }
    
    @objc private func sortButtonTapped() {
        let alertController = UIAlertController(title: "排序", message: nil, preferredStyle: .actionSheet)
        
        for option in SortOption.allCases {
            alertController.addAction(UIAlertAction(title: option.rawValue, style: .default) { [weak self] _ in
                self?.sortMusicItems(by: option)
            })
        }
        
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?[1]
        }
        
        present(alertController, animated: true)
    }
    
    private func sortMusicItems(by option: SortOption) {
        switch option {
        case .title:
            musicItems.sort { $0.title.lowercased() < $1.title.lowercased() }
        case .artist:
            musicItems.sort { ($0.artist ?? "").lowercased() < ($1.artist ?? "").lowercased() }
        case .album:
            musicItems.sort { ($0.album ?? "").lowercased() < ($1.album ?? "").lowercased() }
        case .dateAdded:
            musicItems.sort { $0.dateAdded > $1.dateAdded }
        case .duration:
            musicItems.sort { $0.duration < $1.duration }
        }
        
        tableView.reloadData()
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
extension LibraryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering ? filteredMusicItems.count : musicItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MusicItemCell", for: indexPath) as? MusicItemCell else {
            return UITableViewCell()
        }
        
        let item = isFiltering ? filteredMusicItems[indexPath.row] : musicItems[indexPath.row]
        cell.configure(with: item)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let items = isFiltering ? filteredMusicItems : musicItems
        _ = items[indexPath.row]
        
        musicPlayerService.setQueue(items, startIndex: indexPath.row)
        musicPlayerService.play()
        
        updateMiniPlayerView()
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let items = isFiltering ? filteredMusicItems : musicItems
        let item = items[indexPath.row]
        
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
                        if self.isFiltering, let index = self.filteredMusicItems.firstIndex(where: { $0.id == updatedItem.id }) {
                            self.filteredMusicItems[index] = updatedItem
                        }
                        tableView.reloadRows(at: [indexPath], with: .automatic)
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
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            let item = self.isFiltering ? self.filteredMusicItems[indexPath.row] : self.musicItems[indexPath.row]
            
            self.showConfirmationAlert(
                title: "删除音乐",
                message: "您确定要删除 \(item.title) 吗?",
                confirmAction: {
                    Task {
                        do {
                            try await self.musicLibraryService.deleteMusic(item, musicPlayerService: self.musicPlayerService)
                            
                            await MainActor.run {
                                if self.isFiltering {
                                    self.filteredMusicItems.remove(at: indexPath.row)
                                }
                                self.musicItems = self.musicLibraryService.musicItems
                                self.tableView.reloadData()
                                self.updateEmptyState()
                            }
                        } catch {
                            await MainActor.run {
                                self.showAlert(title: "Error", message: "Failed to delete music: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            )
            
            completion(true)
        }
        
        let addToPlaylistAction = UIContextualAction(style: .normal, title: "添加到专辑") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            let item = self.isFiltering ? self.filteredMusicItems[indexPath.row] : self.musicItems[indexPath.row]
            
            self.showAddToPlaylistOptions(for: item)
            
            completion(true)
        }
        
        addToPlaylistAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [deleteAction, addToPlaylistAction])
    }
    
    private func showAddToPlaylistOptions(for item: MusicItem) {
        let alertController = UIAlertController(title: "添加到专辑", message: nil, preferredStyle: .actionSheet)
        
        // Add to existing playlists
        for playlist in musicLibraryService.playlists {
            alertController.addAction(UIAlertAction(title: playlist.name, style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                Task {
                    do {
                        try await self.musicLibraryService.addToPlaylist(item, playlist: playlist)
                    } catch {
                        await MainActor.run {
                            self.showAlert(title: "错误", message: "添加到专辑失败: \(error.localizedDescription)")
                        }
                    }
                }
            })
        }
        
        // Create new playlist option
        alertController.addAction(UIAlertAction(title: "创建专辑", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            self.showTextInputAlert(
                title: "创建专辑",
                message: "请输入新的专辑名称",
                placeholder: "专辑名称"
            ) { name in
                Task {
                    do {
                        let newPlaylist = try await self.musicLibraryService.createPlaylist(name: name)
                        try await self.musicLibraryService.addToPlaylist(item, playlist: newPlaylist)
                    } catch {
                        await MainActor.run {
                            self.showAlert(title: "错误", message: "创建专辑失败: \(error.localizedDescription)")
                        }
                    }
                }
            }
        })
        
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alertController, animated: true)
    }
}

// MARK: - UISearchResultsUpdating
extension LibraryViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            isFiltering = true
            filteredMusicItems = musicLibraryService.searchMusic(query: searchText)
        } else {
            isFiltering = false
        }
        
        tableView.reloadData()
    }
}

// MARK: - UIDocumentPickerDelegate
extension LibraryViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard !urls.isEmpty else { return }
        
        activityIndicator.startAnimating()
        
        Task {
            do {
                for url in urls {
                    if FileManager.default.isAudioFile(at: url) {
                        let _ = try await musicLibraryService.importMusicFile(from: url)
                    }
                }
                
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.musicItems = self.musicLibraryService.musicItems
                    self.tableView.reloadData()
                    self.updateEmptyState()
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.showAlert(title: "Import Error", message: error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - MiniPlayerViewDelegate
extension LibraryViewController: MiniPlayerViewDelegate {
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
