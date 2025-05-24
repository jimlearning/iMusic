import UIKit

class SearchViewController: UIViewController, MiniPlayerUpdatable {
    
    // MARK: - Properties
    var musicLibraryService: MusicLibraryService!
    var musicPlayerService: MusicPlayerService!
    
    private var searchResults: [MusicItem] = []
    private var isSearching: Bool = false
    
    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.placeholder = "根据标题，艺术家，专辑搜索音乐"
        return controller
    }()
    
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
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        
        let imageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .appSubtext
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Search for music"
        label.textColor = .appSubtext
        label.font = UIFont.systemFont(ofSize: 18)
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        
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
    
    private lazy var noResultsView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No results found"
        label.textColor = .appSubtext
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
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
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMiniPlayerView()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .appBackground
        
        // Setup navigation bar
        title = "Search"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        // Add subviews
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(noResultsView)
        view.addSubview(miniPlayerView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: miniPlayerView.topAnchor),
            
            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: miniPlayerView.topAnchor),
            
            noResultsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            noResultsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noResultsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noResultsView.bottomAnchor.constraint(equalTo: miniPlayerView.topAnchor),
            
            miniPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            miniPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            miniPlayerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            miniPlayerView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func updateViews() {
        if isSearching {
            if searchResults.isEmpty {
                tableView.isHidden = true
                emptyStateView.isHidden = true
                noResultsView.isHidden = false
            } else {
                tableView.isHidden = false
                emptyStateView.isHidden = true
                noResultsView.isHidden = true
            }
        } else {
            tableView.isHidden = true
            emptyStateView.isHidden = false
            noResultsView.isHidden = true
        }
    }
    
    func updateMiniPlayerView() {
        if let currentItem = musicPlayerService.currentItem {
            miniPlayerView.configure(with: currentItem, playbackState: musicPlayerService.playbackState)
            miniPlayerView.isHidden = false
        } else {
            miniPlayerView.isHidden = true
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
extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MusicItemCell", for: indexPath) as? MusicItemCell else {
            return UITableViewCell()
        }
        
        let item = searchResults[indexPath.row]
        cell.configure(with: item)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        _ = searchResults[indexPath.row]
        
        musicPlayerService.setQueue(searchResults, startIndex: indexPath.row)
        musicPlayerService.play()
        
        updateMiniPlayerView()
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = searchResults[indexPath.row]
        
        let favoriteAction = UIContextualAction(style: .normal, title: item.isFavorite ? "取消收藏" : "收藏") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            Task {
                do {
                    let updatedItem = try await self.musicLibraryService.toggleFavorite(item)
                    await MainActor.run {
                        // Update the item in the search results if it's still there
                        if let index = self.searchResults.firstIndex(where: { $0.id == updatedItem.id }) {
                            self.searchResults[index] = updatedItem
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
        let addToPlaylistAction = UIContextualAction(style: .normal, title: "添加到专辑") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            let item = self.searchResults[indexPath.row]
            self.showAddToPlaylistOptions(for: item)
            
            completion(true)
        }
        
        addToPlaylistAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [addToPlaylistAction])
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
        alertController.addAction(UIAlertAction(title: "New Playlist...", style: .default) { [weak self] _ in
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
extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            isSearching = false
            searchResults = []
            tableView.reloadData()
            updateViews()
            return
        }
        
        isSearching = true
        searchResults = musicLibraryService.searchMusic(query: searchText)
        tableView.reloadData()
        updateViews()
    }
}

// MARK: - MiniPlayerViewDelegate
extension SearchViewController: MiniPlayerViewDelegate {
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
