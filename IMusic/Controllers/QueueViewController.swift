import UIKit

class QueueViewController: UIViewController {
    
    // MARK: - Properties
    var musicPlayerService: MusicPlayerService!
    var musicLibraryService: MusicLibraryService!
    
    private var queue: [MusicItem] = []
    private var currentIndex: Int = 0
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MusicItemCell.self, forCellReuseIdentifier: "MusicItemCell")
        tableView.rowHeight = 72
        return tableView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadQueue()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = "当前播放队列"
        view.backgroundColor = .appBackground
        
        // Add close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )
        
        // Add clear button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "清空",
            style: .plain,
            target: self,
            action: #selector(clearButtonTapped)
        )
        
        // Add table view
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadQueue() {
        queue = musicPlayerService.queue
        currentIndex = musicPlayerService.queueIndex
        tableView.reloadData()
        
        // Scroll to current item
        if !queue.isEmpty && currentIndex < queue.count {
            tableView.scrollToRow(at: IndexPath(row: currentIndex, section: 0), at: .middle, animated: true)
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func clearButtonTapped() {
        showConfirmationAlert(
            title: "清空播放队列",
            message: "确定要清空当前播放队列吗？",
            confirmAction: {
                self.musicPlayerService.stop()
                self.musicPlayerService.setQueue([])
                self.dismiss(animated: true)
            }
        )
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension QueueViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return queue.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MusicItemCell", for: indexPath) as? MusicItemCell else {
            return UITableViewCell()
        }
        
        let item = queue[indexPath.row]
        cell.configure(with: item)
        
        // Highlight current item
        if indexPath.row == currentIndex {
            cell.accessoryType = .checkmark
            cell.tintColor = .appPrimary
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Play selected item
        musicPlayerService.playQueueItem(at: indexPath.row)
        
        // Update UI
        currentIndex = indexPath.row
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = queue[indexPath.row]
        
        let favoriteAction = UIContextualAction(style: .normal, title: item.isFavorite ? "取消收藏" : "收藏") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            Task {
                do {
                    let updatedItem = try await self.musicLibraryService.toggleFavorite(item)
                    await MainActor.run {
                        // Update the item in the queue
                        if let _ = self.musicPlayerService.queue.firstIndex(where: { $0.id == updatedItem.id }) {
                            // We need to reload the queue since the musicPlayerService queue was updated
                            self.loadQueue()
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
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let removeAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            self.musicPlayerService.removeFromQueue(at: indexPath.row)
            self.loadQueue()
            
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [removeAction])
    }
}
