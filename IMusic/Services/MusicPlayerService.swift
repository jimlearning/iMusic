import Foundation
import AVFoundation
import MediaPlayer
import UIKit

enum PlaybackState {
    case stopped
    case playing
    case paused
    case loading
}

class MusicPlayerService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    // Notification name for track change
    static let trackChangedNotification = Notification.Name("com.imusic.trackChanged")
    private var player: AVAudioPlayer?
    private var audioSession: AVAudioSession
    private let musicLibrary: MusicLibraryService
    
    // Playback state
    @Published var currentItem: MusicItem?
    @Published var playbackState: PlaybackState = .stopped
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var progress: Float = 0
    
    // Playback queue
    @Published var queue: [MusicItem] = []
    @Published var queueIndex: Int = 0
    
    // Settings
    @Published var volume: Float = 0.7 {
        didSet {
            player?.volume = volume
        }
    }
    @Published var isShuffleEnabled: Bool = false
    @Published var repeatMode: RepeatMode = .none
    
    private var timer: Timer?
    private var shuffledIndices: [Int] = []
    
    init(musicLibrary: MusicLibraryService) {
        self.musicLibrary = musicLibrary
        self.audioSession = AVAudioSession.sharedInstance()
        
        super.init()
        
        setupAudioSession()
        setupRemoteCommandCenter()
        
        // Load user settings
        Task { [weak self] in
            await self?.loadUserSettings()
        }
    }
    
    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func play() {
        guard let player = player else {
            if let currentItem = currentItem {
                loadAndPlay(item: currentItem)
            } else if !queue.isEmpty {
                playQueueItem(at: queueIndex)
            }
            return
        }
        
        player.play()
        playbackState = .playing
        startTimer()
        updateNowPlayingInfo()
    }
    
    func pause() {
        player?.pause()
        playbackState = .paused
        timer?.invalidate()
        timer = nil
        updateNowPlayingInfo()
    }
    
    func stop() {
        player?.stop()
        player = nil
        playbackState = .stopped
        currentTime = 0
        progress = 0
        timer?.invalidate()
        timer = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    func togglePlayPause() {
        if playbackState == .playing {
            pause()
        } else {
            play()
        }
    }
    
    func seek(to time: TimeInterval) {
        guard let player = player else { return }
        
        player.currentTime = time
        currentTime = time
        progress = Float(time / duration)
        updateNowPlayingInfo()
    }
    
    func seekToPercent(_ percent: Float) {
        guard let player = player, duration > 0 else { return }
        
        let targetTime = TimeInterval(percent) * duration
        player.currentTime = targetTime
        currentTime = targetTime
        progress = percent
        updateNowPlayingInfo()
    }
    
    func playItem(_ item: MusicItem) {
        loadAndPlay(item: item)
    }
    
    func playNext() {
        if queue.isEmpty || queueIndex >= queue.count - 1 {
            if repeatMode == .all {
                queueIndex = 0
                playQueueItem(at: queueIndex)
            } else {
                stop()
            }
        } else {
            queueIndex += 1
            playQueueItem(at: queueIndex)
        }
    }
    
    func playPrevious() {
        if currentTime > 3 {
            // If we're more than 3 seconds into the song, restart it
            seek(to: 0)
        } else if queueIndex > 0 {
            queueIndex -= 1
            playQueueItem(at: queueIndex)
        } else if repeatMode == .all {
            queueIndex = queue.count - 1
            playQueueItem(at: queueIndex)
        } else {
            seek(to: 0)
        }
    }
    
    func setQueue(_ items: [MusicItem], startIndex: Int = 0) {
        queue = items
        queueIndex = min(startIndex, items.count - 1)
        
        if isShuffleEnabled {
            generateShuffledIndices()
        }
        
        if !items.isEmpty {
            playQueueItem(at: queueIndex)
        } else {
            stop()
        }
    }
    
    func addToQueue(_ item: MusicItem) {
        queue.append(item)
        
        if isShuffleEnabled {
            generateShuffledIndices()
        }
        
        if queue.count == 1 {
            queueIndex = 0
            playQueueItem(at: 0)
        }
    }
    
    func removeFromQueue(at index: Int) {
        guard index >= 0 && index < queue.count else { return }
        
        let wasPlaying = (index == queueIndex)
        
        queue.remove(at: index)
        
        if isShuffleEnabled {
            generateShuffledIndices()
        }
        
        if wasPlaying {
            if queue.isEmpty {
                stop()
            } else if queueIndex >= queue.count {
                queueIndex = queue.count - 1
                playQueueItem(at: queueIndex)
            } else {
                playQueueItem(at: queueIndex)
            }
        } else if index < queueIndex {
            queueIndex -= 1
        }
    }
    
    func toggleShuffle() {
        isShuffleEnabled.toggle()
        
        if isShuffleEnabled {
            generateShuffledIndices()
        }
        
        Task {
            await saveUserSettings()
        }
    }
    
    func toggleRepeatMode() {
        switch repeatMode {
        case .none:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .none
        }
        
        Task {
            await saveUserSettings()
        }
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        
        Task {
            await saveUserSettings()
        }
    }
    
    func updateCurrentItemFavoriteStatus(_ isFavorite: Bool) {
        guard var item = currentItem else { return }
        
        // Update the favorite status of the current item
        item.isFavorite = isFavorite
        currentItem = item
        
        // Notify that the current item has been updated
        NotificationCenter.default.post(name: MusicPlayerService.trackChangedNotification, object: nil)
    }
    
    // MARK: - Private Methods
    
    private func loadAndPlay(item: MusicItem) {
        playbackState = .loading
        
        // Get the full path for the item
        let fullPath = musicLibrary.getFullPath(for: item.filePath)
        print("Attempting to play file at path: \(fullPath.path)")
        
        do {
            // Ensure audio session is active
            try audioSession.setActive(true)
            
            player = try AVAudioPlayer(contentsOf: fullPath)
            player?.delegate = self
            player?.volume = volume
            player?.prepareToPlay()
            
            // Set current item and start playing
            currentItem = item
            duration = player?.duration ?? 0
            currentTime = 0
            progress = 0
            
            player?.play()
            playbackState = .playing
            
            // Start timer to update progress
            startTimer()
            
            // Update now playing info
            updateNowPlayingInfo()
            
            // Post notification that track changed
            print("Posting trackChangedNotification for new track: \(item.title)")
            NotificationCenter.default.post(name: MusicPlayerService.trackChangedNotification, object: nil)
            
            // Save current item to user settings immediately
            print("Saving current item to user settings immediately after playback starts")
            Task {
                await saveUserSettings()
            }
        } catch {
            print("Error loading audio file: \(error)")
            handlePlaybackError(error)
        }
    }
    
    func playQueueItem(at index: Int) {
        guard index >= 0 && index < queue.count else { return }
        
        queueIndex = index
        let item = queue[index]
        
        // If the currently playing music is the same as the selected music to start playing, continue playback
        if let currentItem = currentItem, currentItem.id == item.id {
            if playbackState == .paused {
                play()
            }
            return
        }
        
        // Set current item and load it
        currentItem = item
        loadAndPlay(item: item)
        
        // Post notification that track has changed
        NotificationCenter.default.post(name: MusicPlayerService.trackChangedNotification, object: self)
        
        // Save current item to user settings
        Task {
            await saveUserSettings()
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            
            self.currentTime = player.currentTime
            
            if self.duration > 0 {
                self.progress = Float(self.currentTime / self.duration)
            } else {
                self.progress = 0
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            print("Audio session setup successfully")
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(to: event.positionTime)
                return .success
            }
            return .commandFailed
        }
    }
    
    private func updateNowPlayingInfo() {
        guard let currentItem = currentItem else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo = [String: Any]()
        
        // Set title, artist, album
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentItem.title
        
        if let artist = currentItem.artist {
            nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        }
        
        if let album = currentItem.album {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
        }
        
        // Set duration and current time
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        
        // Set playback rate
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playbackState == .playing ? 1.0 : 0.0
        
        // Set artwork if available
        if let artworkData = currentItem.artworkData, let image = UIImage(data: artworkData) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        // Update the now playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        print("Updated now playing info for: \(currentItem.title)")
    }
    
    private func handlePlaybackError(_ error: Error) {
        print("Playback error: \(error.localizedDescription)")
        
        // Log additional error details if available
        if let nsError = error as NSError? {
            print("Error domain: \(nsError.domain), code: \(nsError.code)")
            if let failureReason = nsError.localizedFailureReason {
                print("Failure reason: \(failureReason)")
            }
        }
        
        // Stop playback and reset player state
        stop()
    }
    
    private func generateShuffledIndices() {
        shuffledIndices = Array(0..<queue.count)
        shuffledIndices.shuffle()
        
        // Make sure the current item stays at its position
        if !queue.isEmpty && queueIndex < queue.count {
            if let shuffledIndex = shuffledIndices.firstIndex(of: queueIndex) {
                shuffledIndices.swapAt(0, shuffledIndex)
            }
        }
    }
    
    private func loadUserSettings() async {
        do {
            let settings = try await musicLibrary.dataProvider.getUserSettings()
            print("Loaded user settings, last played item: \(settings.lastPlayedMusicItem?.title ?? "none")")
            
            await MainActor.run {
                self.volume = settings.volume
                self.isShuffleEnabled = settings.shuffleEnabled
                self.repeatMode = settings.repeatMode
                
                if let player = self.player {
                    player.volume = self.volume
                }
                
                // Load last played music item if available
                if let lastPlayedItem = settings.lastPlayedMusicItem {
                    print("Setting current item to last played: \(lastPlayedItem.title)")
                    self.currentItem = lastPlayedItem
                    self.currentTime = settings.lastPlaybackPosition
                    
                    // Notify that track has changed
                    print("Posting trackChangedNotification from loadUserSettings")
                    NotificationCenter.default.post(name: MusicPlayerService.trackChangedNotification, object: nil)
                    
                    // 立即保存用户设置，确保设置正确保存
                    Task {
                        await self.saveUserSettings()
                    }
                } else {
                    print("No last played item found in user settings")
                }
            }
        } catch {
            print("Failed to load user settings: \(error)")
        }
    }
    
    private func saveUserSettings() async {
        do {
            // 创建新的 UserSettings 实例，而不是加载现有的
            var settings = UserSettings()
            
            settings.volume = volume
            settings.shuffleEnabled = isShuffleEnabled
            settings.repeatMode = repeatMode
            
            // Save last played music item and position
            settings.lastPlayedMusicItem = currentItem
            settings.lastPlaybackPosition = currentTime
            
            if let item = currentItem {
                print("Saving current item to user settings: \(item.title)")
            } else {
                print("No current item to save to user settings")
            }
            
            try await musicLibrary.dataProvider.saveUserSettings(settings)
            print("User settings saved successfully with lastPlayedMusicItem: \(settings.lastPlayedMusicItem?.title ?? "none")")
        } catch {
            print("Failed to save user settings: \(error)")
        }
    }
    
    // Helper method to resolve relative paths to absolute paths
    func resolveFilePath(_ relativePath: String) -> URL {
        return musicLibrary.getFullPath(for: relativePath)
    }
    
    // MARK: - AVAudioPlayerDelegate Implementation
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("AVAudioPlayer finished playing, success: \(flag)")
        if flag {
            switch repeatMode {
            case .none:
                playNext()
            case .all:
                playNext()
            case .one:
                // Restart the current track
                seek(to: 0)
                play()
            }
        } else {
            handlePlaybackError(NSError(domain: "MusicPlayerService", code: 500, 
                                       userInfo: [NSLocalizedDescriptionKey: "播放结束"]))
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("AVAudioPlayer decode error: \(error.localizedDescription)")
            handlePlaybackError(error)
        }
    }
}
