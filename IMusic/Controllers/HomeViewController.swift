import UIKit
import Foundation

class HomeViewController: UIViewController, MiniPlayerUpdatable {
    
    // MARK: - Layout Constants
    private struct LayoutMetrics {
        // Margins and Spacing
        static let standardMargin: CGFloat = 20
        static let cellSpacing: CGFloat = 20
        
        // Heights
        static let featuredViewHeight: CGFloat = 300
        static let segmentContainerHeight: CGFloat = 50
        static let minimumCollectionViewHeight: CGFloat = 100
        static let cellAdditionalHeight: CGFloat = 60 // Title and other elements height in cell
    }
    
    // MARK: - Properties
    var musicLibraryService: MusicLibraryService!
    var musicPlayerService: MusicPlayerService!
    
    private var featuredPlaylist: PlaylistItem?
    private var recommendedPlaylists: [PlaylistItem] = []
    private var sleepPlaylists: [PlaylistItem] = []
    private var relaxPlaylists: [PlaylistItem] = []
    private var focusPlaylists: [PlaylistItem] = []
    
    // Properties for implementing sticky header effect
    private var segmentControlTopConstraint: NSLayoutConstraint!
    private var segmentContainerHeight: CGFloat = 60
    private var segmentYThreshold: CGFloat = 0
    
    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var featuredView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var gradientView: GradientView = {
        let view = GradientView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setGradient(colors: [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.7).cgColor
        ], locations: [0.5, 1.0])
        return view
    }()
    
    private lazy var featuredImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemPurple
        return imageView
    }()
    
    private lazy var featuredTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private lazy var featuredArtistLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        return label
    }()
    
    private lazy var segmentContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private lazy var categorySegmentedControl: UISegmentedControl = {
        let items = ["推荐", "助眠", "放松", "专注"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.backgroundColor = .systemBackground
        segmentedControl.selectedSegmentTintColor = UIColor(red: 95/255, green: 186/255, blue: 125/255, alpha: 1.0) // Green
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.darkGray], for: .normal)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentedControl.setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        segmentedControl.addTarget(self, action: #selector(categoryChanged(_:)), for: .valueChanged)
        return segmentedControl
    }()
    
    private lazy var playlistCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PlaylistCollectionViewCell.self, forCellWithReuseIdentifier: "PlaylistCell")
        
        // 禁用 cell 尺寸变化的隐式动画
        collectionView.layer.shouldRasterize = true
        collectionView.layer.rasterizationScale = UIScreen.main.scale
        return collectionView
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
        
        scrollView.delegate = self
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(musicLibraryDidLoad), 
            name: NSNotification.Name("MusicLibraryDidLoadNotification"), 
            object: nil
        )
        
        // Add observer for metadata update completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataUpdateCompleted), 
            name: DefaultPlaylistsManager.metadataUpdateCompletedNotification, 
            object: nil
        )
        
        // Add observer for track change notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(trackChanged), 
            name: MusicPlayerService.trackChangedNotification, 
            object: nil
        )
                
        loadData()
    }
    
    // viewDidLayoutSubviews 方法已移除，动画禁用逻辑移至 loadData 方法中
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadData()
        updateMiniPlayerView()
    }
    
    @objc private func musicLibraryDidLoad() {
        print("Music library did load notification received")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.loadData()
        }
    }
    
    @objc private func metadataUpdateCompleted() {
        print("Metadata update completed notification received")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Reload data to reflect updated metadata
            self.loadData()
            
            // Update mini player if it's visible
            self.updateMiniPlayerView()
        }
    }
    
    @objc private func trackChanged() {
        print("Track changed notification received in HomeViewController")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update mini player to show the new track
            self.updateMiniPlayerView()
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(featuredView)
        featuredView.addSubview(featuredImageView)
        featuredView.addSubview(gradientView)
        featuredView.addSubview(featuredTitleLabel)
        featuredView.addSubview(featuredArtistLabel)
        
        view.addSubview(segmentContainerView)
        segmentContainerView.addSubview(categorySegmentedControl)
        
        contentView.addSubview(playlistCollectionView)
        
        view.addSubview(miniPlayerView)
        
        // Calculate threshold position for segment control sticky behavior
        // Add standardMargin to ensure proper spacing between featuredView and segmentContainerView
        segmentYThreshold = LayoutMetrics.featuredViewHeight + LayoutMetrics.standardMargin * 2
        
        segmentControlTopConstraint = segmentContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: segmentYThreshold)
        segmentControlTopConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            
            // Featured view
            featuredView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: LayoutMetrics.standardMargin),
            featuredView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: LayoutMetrics.standardMargin),
            featuredView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -LayoutMetrics.standardMargin),
            featuredView.heightAnchor.constraint(equalToConstant: LayoutMetrics.featuredViewHeight),
            
            // Featured image view - fill the entire featured view
            featuredImageView.topAnchor.constraint(equalTo: featuredView.topAnchor),
            featuredImageView.leadingAnchor.constraint(equalTo: featuredView.leadingAnchor),
            featuredImageView.trailingAnchor.constraint(equalTo: featuredView.trailingAnchor),
            featuredImageView.bottomAnchor.constraint(equalTo: featuredView.bottomAnchor),
            
            // Gradient view for text readability
            gradientView.leadingAnchor.constraint(equalTo: featuredView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: featuredView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: featuredView.bottomAnchor),
            gradientView.heightAnchor.constraint(equalTo: featuredView.heightAnchor, multiplier: 0.5),
            
            // Featured title label
            featuredTitleLabel.leadingAnchor.constraint(equalTo: featuredView.leadingAnchor, constant: 16),
            featuredTitleLabel.bottomAnchor.constraint(equalTo: featuredArtistLabel.topAnchor, constant: -4),
            featuredTitleLabel.trailingAnchor.constraint(equalTo: featuredView.trailingAnchor, constant: -16),
            
            // Featured artist label
            featuredArtistLabel.leadingAnchor.constraint(equalTo: featuredView.leadingAnchor, constant: 16),
            featuredArtistLabel.bottomAnchor.constraint(equalTo: featuredView.bottomAnchor, constant: -16),
            featuredArtistLabel.trailingAnchor.constraint(equalTo: featuredView.trailingAnchor, constant: -16),
            
            // Segment container view
            segmentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            segmentContainerView.heightAnchor.constraint(equalToConstant: LayoutMetrics.segmentContainerHeight),
            
            // Category segmented control
            categorySegmentedControl.leadingAnchor.constraint(equalTo: segmentContainerView.leadingAnchor, constant: LayoutMetrics.standardMargin),
            categorySegmentedControl.trailingAnchor.constraint(equalTo: segmentContainerView.trailingAnchor, constant: -LayoutMetrics.standardMargin),
            categorySegmentedControl.centerYAnchor.constraint(equalTo: segmentContainerView.centerYAnchor),
            categorySegmentedControl.heightAnchor.constraint(equalToConstant: 36),
            
            // Playlist collection view
            playlistCollectionView.topAnchor.constraint(equalTo: featuredView.bottomAnchor, constant: LayoutMetrics.standardMargin * 2 + LayoutMetrics.segmentContainerHeight),
            playlistCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: LayoutMetrics.standardMargin),
            playlistCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -LayoutMetrics.standardMargin),
            // Add extra bottom padding to avoid content being hidden by mini player
            playlistCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -(LayoutMetrics.standardMargin + 60)),
            
            // Mini player view
            miniPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            miniPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            miniPlayerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            miniPlayerView.heightAnchor.constraint(equalToConstant: 60),
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(featuredViewTapped))
        featuredView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        let playlists = musicLibraryService.playlists
        print("Found \(playlists.count) playlists")
        
        recommendedPlaylists.removeAll()
        sleepPlaylists.removeAll()
        relaxPlaylists.removeAll()
        focusPlaylists.removeAll()
        
        if !playlists.isEmpty {
            let randomIndex = Int.random(in: 0..<playlists.count)
            featuredPlaylist = playlists[randomIndex]
            updateFeaturedView()
        }
        
        // Categorize playlists based on their category
        for playlist in playlists {
            // Check the playlist's category
            switch playlist.category {
            case DefaultPlaylistsManager.recommendedCategory:
                recommendedPlaylists.append(playlist)
            case DefaultPlaylistsManager.sleepCategory:
                sleepPlaylists.append(playlist)
            case DefaultPlaylistsManager.relaxCategory:
                relaxPlaylists.append(playlist)
            case DefaultPlaylistsManager.focusCategory:
                focusPlaylists.append(playlist)
            case "":
                // For playlists without a category, add to recommended category
                recommendedPlaylists.append(playlist)
            default:
                // For playlists with unknown categories, add to recommended category
                recommendedPlaylists.append(playlist)
            }
        }
        
        // 数据准备好后，禁用动画效果重新加载
        UIView.performWithoutAnimation {
            playlistCollectionView.reloadData()
            playlistCollectionView.layoutIfNeeded()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateCollectionViewHeight()
        }
    }
    
    private func updateCollectionViewHeight() {
        // Get playlists for current category
        let playlists = getCurrentPlaylists()
        
        // Calculate required rows (2 items per row)
        let numberOfItems = playlists.count
        let numberOfRows = (numberOfItems + 1) / 2 // Round up
        
        // Calculate cell dimensions
        let availableWidth = playlistCollectionView.bounds.width - LayoutMetrics.standardMargin
        let cellWidth = (availableWidth - LayoutMetrics.cellSpacing) / 2 // Match calculation in sizeForItemAt
        let cellHeight = cellWidth + LayoutMetrics.cellAdditionalHeight
        
        // Calculate total height
        var totalHeight: CGFloat = 0
        
        if numberOfItems == 0 {
            // Set minimum height if no items
            totalHeight = LayoutMetrics.minimumCollectionViewHeight
        } else {
            // rows * cellHeight + (rows-1) * spacing
            totalHeight = CGFloat(numberOfRows) * cellHeight
            if numberOfRows > 1 {
                totalHeight += CGFloat(numberOfRows - 1) * LayoutMetrics.cellSpacing
            }
        }
        
        // Update collection view height constraint
        for constraint in playlistCollectionView.constraints where constraint.firstAttribute == .height {
            constraint.isActive = false
        }
        
        // Add new height constraint
        let heightConstraint = playlistCollectionView.heightAnchor.constraint(equalToConstant: totalHeight)
        heightConstraint.isActive = true
        
        // Update layout
        UIView.performWithoutAnimation {
            self.view.layoutIfNeeded()
        }
    }
    
    func updateMiniPlayerView() {
        print("HomeViewController: updateMiniPlayerView called")
        if let currentItem = musicPlayerService.currentItem {
            print("HomeViewController: Configuring mini player with item: \(currentItem.title)")
            miniPlayerView.configure(with: currentItem, playbackState: musicPlayerService.playbackState)
            miniPlayerView.isHidden = false
        } else {
            print("HomeViewController: No current item, hiding mini player")
            miniPlayerView.isHidden = true
        }
    }
    
    private func updateFeaturedView() {
        guard let playlist = featuredPlaylist else { return }
        
        featuredTitleLabel.text = playlist.name
        
        // Set artist name if available, otherwise use number of tracks
        if let firstItem = playlist.musicItems.first, let artist = firstItem.artist {
            featuredArtistLabel.text = artist
        } else {
            let trackCount = playlist.musicItems.count
            featuredArtistLabel.text = "\(trackCount) \(trackCount == 1 ? "track" : "tracks")"
        }
        
        // Set featured image if available
        if let firstItem = playlist.musicItems.first, let artworkData = firstItem.artworkData, let image = UIImage(data: artworkData) {
            featuredImageView.image = image
            featuredImageView.contentMode = .scaleAspectFill
        } else {
            // Use a placeholder color based on playlist name
            featuredImageView.image = UIImage(systemName: "music.note")?.withRenderingMode(.alwaysTemplate)
            featuredImageView.contentMode = .scaleAspectFit
            featuredImageView.tintColor = .white
            featuredImageView.backgroundColor = colorBasedOnString(playlist.name)
        }
    }
    
    // MARK: - Actions
    
    @objc private func categoryChanged(_ sender: UISegmentedControl) {
        // 数据准备好后，禁用动画效果重新加载
        UIView.performWithoutAnimation {
            playlistCollectionView.reloadData()
            playlistCollectionView.layoutIfNeeded()
        }
        
        // Update collection view height after category change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateCollectionViewHeight()
        }
    }
    
    @objc private func featuredViewTapped() {
        guard let playlist = featuredPlaylist else { return }
        
        let playlistDetailVC = PlaylistDetailViewController()
        playlistDetailVC.musicLibraryService = musicLibraryService
        playlistDetailVC.musicPlayerService = musicPlayerService
        playlistDetailVC.playlist = playlist
        
        navigationController?.pushViewController(playlistDetailVC, animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentPlaylists() -> [PlaylistItem] {
        switch categorySegmentedControl.selectedSegmentIndex {
        case 0:
            return recommendedPlaylists
        case 1:
            return sleepPlaylists
        case 2:
            return relaxPlaylists
        case 3:
            return focusPlaylists
        default:
            return recommendedPlaylists
        }
    }
}

// MARK: - UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return getCurrentPlaylists().count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaylistCell", for: indexPath) as? PlaylistCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let playlists = getCurrentPlaylists()
        if indexPath.item < playlists.count {
            let playlist = playlists[indexPath.item]
            cell.configure(with: playlist)
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let playlists = getCurrentPlaylists()
        if indexPath.item < playlists.count {
            let playlist = playlists[indexPath.item]
            
            let playlistDetailVC = PlaylistDetailViewController()
            playlistDetailVC.musicLibraryService = musicLibraryService
            playlistDetailVC.musicPlayerService = musicPlayerService
            playlistDetailVC.playlist = playlist
            
            navigationController?.pushViewController(playlistDetailVC, animated: true)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Calculate cell width to display two cells per row
        let availableWidth = collectionView.bounds.width - LayoutMetrics.standardMargin
        let width = (availableWidth - LayoutMetrics.cellSpacing) / 2
        
        // Fixed height ratio to ensure consistent cell sizes
        return CGSize(width: width, height: width + LayoutMetrics.cellAdditionalHeight)
    }
    
    // Set section insets
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    // Set line spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return LayoutMetrics.cellSpacing
    }
    
    // Set item spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return LayoutMetrics.cellSpacing
    }
}

// MARK: - UIScrollViewDelegate
extension HomeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        
        // Apply sticky behavior when scrolling past threshold
        if offset > segmentYThreshold {
            // Sticky effect
            segmentControlTopConstraint.constant = 0
            segmentContainerView.backgroundColor = .systemBackground
        } else {
            // Normal scrolling effect
            segmentControlTopConstraint.constant = segmentYThreshold - offset
            
            // Gradually increase background opacity when approaching sticky position
            let progress = offset / segmentYThreshold
            let alpha = min(1.0, max(0.0, progress))
            segmentContainerView.backgroundColor = UIColor.systemBackground.withAlphaComponent(alpha)
        }
        
        // Update layout
        view.layoutIfNeeded()
    }
}

// MARK: - MiniPlayerViewDelegate
extension HomeViewController: MiniPlayerViewDelegate {
    func miniPlayerViewDidTapPlayPause(_ miniPlayerView: MiniPlayerView) {
        musicPlayerService.togglePlayPause()
        updateMiniPlayerView()
    }
    
    func miniPlayerViewDidTapView(_ miniPlayerView: MiniPlayerView) {
        if musicPlayerService.currentItem != nil {
            let nowPlayingVC = NowPlayingViewController()
            nowPlayingVC.musicPlayerService = musicPlayerService
            nowPlayingVC.musicLibraryService = musicLibraryService
            nowPlayingVC.modalPresentationStyle = .fullScreen
            present(nowPlayingVC, animated: true)
        }
    }
}
