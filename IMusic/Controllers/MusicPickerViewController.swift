import UIKit

protocol MusicPickerViewControllerDelegate: AnyObject {
    func musicPickerDidSelectItems(_ items: [MusicItem])
}

class MusicPickerViewController: UIViewController {
    
    // MARK: - Properties
    var musicLibraryService: MusicLibraryService!
    var selectedPlaylist: PlaylistItem!
    weak var delegate: MusicPickerViewControllerDelegate?
    
    private var musicItems: [MusicItem] = []
    private var filteredMusicItems: [MusicItem] = []
    private var selectedItems: [MusicItem] = []
    private var isFiltering: Bool = false
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MusicItemCell.self, forCellReuseIdentifier: "MusicItemCell")
        tableView.allowsMultipleSelection = true
        tableView.rowHeight = 72
        return tableView
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("添加选定 (0)", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .appPrimary
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.isEnabled = false
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMusicLibrary()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = "添加到专辑"
        view.backgroundColor = .appBackground
        
        view.addSubview(tableView)
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -16),
            
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Setup search controller
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "搜索音乐"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    // MARK: - Data Loading
    
    private func loadMusicLibrary() {
        musicItems = musicLibraryService.musicItems
        
        // Filter out items that are already in the playlist
        let playlistItemIds = Set(selectedPlaylist.musicItems.map { $0.id })
        musicItems = musicItems.filter { !playlistItemIds.contains($0.id) }
        
        tableView.reloadData()
    }
    
    private func updateAddButton() {
        let count = selectedItems.count
        addButton.setTitle("添加选定 (\(count))", for: .normal)
        addButton.isEnabled = count > 0
    }
    
    // MARK: - Actions
    
    @objc private func addButtonTapped() {
        delegate?.musicPickerDidSelectItems(selectedItems)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension MusicPickerViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering ? filteredMusicItems.count : musicItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MusicItemCell", for: indexPath) as? MusicItemCell else {
            return UITableViewCell()
        }
        
        let item = isFiltering ? filteredMusicItems[indexPath.row] : musicItems[indexPath.row]
        cell.configure(with: item)
        
        // Check if the item is already selected
        if selectedItems.contains(where: { $0.id == item.id }) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = isFiltering ? filteredMusicItems[indexPath.row] : musicItems[indexPath.row]
        
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }
        
        if !selectedItems.contains(where: { $0.id == item.id }) {
            selectedItems.append(item)
            updateAddButton()
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let item = isFiltering ? filteredMusicItems[indexPath.row] : musicItems[indexPath.row]
        
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }
        
        selectedItems.removeAll { $0.id == item.id }
        updateAddButton()
    }
}

// MARK: - UISearchResultsUpdating
extension MusicPickerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            isFiltering = true
            filteredMusicItems = musicItems.filter { item in
                return item.title.lowercased().contains(searchText.lowercased()) ||
                       (item.artist?.lowercased().contains(searchText.lowercased()) ?? false) ||
                       (item.album?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        } else {
            isFiltering = false
        }
        
        tableView.reloadData()
    }
}
