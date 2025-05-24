import Foundation
@preconcurrency import AVFoundation
import UIKit

class MusicLibraryService: ObservableObject {
    let dataProvider: DataProvider
    let documentDirectory: URL
    
    @Published var musicItems: [MusicItem] = []
    @Published var playlists: [PlaylistItem] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    init(dataProvider: DataProvider = LocalDataProvider()) {
        self.dataProvider = dataProvider
        self.documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        Task {
            print("MusicLibraryService initialization started")
            // First initialize default playlists, then load all data
            await initializeDefaultPlaylists()
            await loadData()
            print("MusicLibraryService initialization completed with \(playlists.count) playlists and \(musicItems.count) music items")
            
            // 发送通知，告知数据加载完成
            NotificationCenter.default.post(name: NSNotification.Name("MusicLibraryDidLoadNotification"), object: nil)
        }
    }
    
    // Initialize default category playlists if they don't exist
    private func initializeDefaultPlaylists() async {
        // Create default playlists from bundled resources
        await DefaultPlaylistsManager.createDefaultPlaylists(musicLibraryService: self)
    }
    
    // MARK: - Public Methods
    
    func loadData() async {
        await setLoading(true)
        
        do {
            self.musicItems = try await dataProvider.getAllMusic()
            self.playlists = try await dataProvider.getPlaylists()
            await setError(nil)
        } catch {
            await setError(error)
        }
        
        await setLoading(false)
    }
    
    func importMusicFile(from url: URL) async throws -> MusicItem {
        await setLoading(true)
        defer { Task { await self.setLoading(false) } }
        
        // Create a copy of the file in the app's document directory
        let fileName = url.lastPathComponent
        let destinationURL = documentDirectory.appendingPathComponent(fileName)
        
        // Check if file already exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            throw NSError(domain: "MusicLibraryService", code: 409, 
                          userInfo: [NSLocalizedDescriptionKey: "A file with this name already exists."])
        }
        
        // Copy the file
        try FileManager.default.copyItem(at: url, to: destinationURL)
        
        // Extract metadata
        let asset = AVAsset(url: destinationURL)
        
        do {
            let metadata = try await extractMetadata(from: asset)
            let relativePath = fileName
            
            let musicItem = MusicItem(
                title: metadata.title ?? fileName,
                artist: metadata.artist,
                album: metadata.album,
                duration: metadata.duration,
                filePath: relativePath,
                artworkData: metadata.artworkData
            )
            
            // Save to library
            await MainActor.run {
                var updatedLibrary = self.musicItems
                updatedLibrary.append(musicItem)
                self.musicItems = updatedLibrary
                
                // Save the updated library
                Task {
                    try? await self.dataProvider.saveMusic(self.musicItems)
                }
            }
            
            return musicItem
        } catch {
            // Clean up file if metadata extraction fails
            try? FileManager.default.removeItem(at: destinationURL)
            throw error
        }
    }
    
    func deleteMusic(_ item: MusicItem, musicPlayerService: MusicPlayerService? = nil) async throws {
        await setLoading(true)
        defer { Task { await self.setLoading(false) } }
        
        // Check if the item being deleted is currently playing
        if let playerService = musicPlayerService, let currentItem = playerService.currentItem, currentItem.id == item.id {
            print("Currently playing item is being deleted, switching to next track")
            // If the current item is being deleted, play the next track in the queue
            playerService.playNext()
        }
        
        // Delete the file
        let fullPath = getFullPath(for: item.filePath)
        if FileManager.default.fileExists(atPath: fullPath.path) {
            try FileManager.default.removeItem(at: fullPath)
        }
        
        // Update data provider
        try await dataProvider.deleteMusic(item)
        
        // Update local state
        await loadData()
    }
    
    func createPlaylist(name: String) async throws -> PlaylistItem {
        await setLoading(true)
        defer { Task { await self.setLoading(false) } }
        
        let playlist = try await dataProvider.createPlaylist(name: name, items: [])
        
        await MainActor.run {
            self.playlists.append(playlist)
        }
        
        return playlist
    }
    
    func deletePlaylist(_ playlist: PlaylistItem) async throws {
        await setLoading(true)
        defer { Task { await self.setLoading(false) } }
        
        try await dataProvider.deletePlaylist(playlist)
        
        await MainActor.run {
            self.playlists.removeAll { $0.id == playlist.id }
        }
    }
    
    func addToPlaylist(_ music: MusicItem, playlist: PlaylistItem) async throws {
        await setLoading(true)
        defer { Task { await self.setLoading(false) } }
        
        let updatedPlaylist = try await dataProvider.addMusicToPlaylist(music, playlist: playlist)
        
        await updatePlaylistInState(updatedPlaylist)
    }
    
    func removeFromPlaylist(_ music: MusicItem, playlist: PlaylistItem) async throws {
        await setLoading(true)
        defer { Task { await self.setLoading(false) } }
        
        let updatedPlaylist = try await dataProvider.removeMusicFromPlaylist(music, playlist: playlist)
        
        await updatePlaylistInState(updatedPlaylist)
    }
    
    func renamePlaylist(_ playlist: PlaylistItem, newName: String) async throws {
        await setLoading(true)
        defer { Task { await self.setLoading(false) } }
        
        var updatedPlaylist = playlist
        updatedPlaylist.name = newName
        
        try await dataProvider.updatePlaylist(updatedPlaylist)
        
        await updatePlaylistInState(updatedPlaylist)
    }
    
    func searchMusic(query: String) -> [MusicItem] {
        if query.isEmpty {
            return musicItems
        }
        
        let lowercasedQuery = query.lowercased()
        return musicItems.filter { item in
            return item.title.lowercased().contains(lowercasedQuery) ||
                   (item.artist?.lowercased().contains(lowercasedQuery) ?? false) ||
                   (item.album?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }
    
    // MARK: - Path Helpers
    
    func getFullPath(for relativePath: String) -> URL {
        return documentDirectory.appendingPathComponent(relativePath)
    }
    
    func getRelativePath(for fullPath: URL) -> String? {
        let docPath = documentDirectory.path
        let fullPathString = fullPath.path
        
        if fullPathString.hasPrefix(docPath) {
            let pathSuffix = String(fullPathString.dropFirst(docPath.count))
            // Remove leading slash if present
            return pathSuffix.hasPrefix("/") ? String(pathSuffix.dropFirst()) : pathSuffix
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    private func extractMetadata(from asset: AVAsset) async throws -> (title: String?, artist: String?, album: String?, duration: Double, artworkData: Data?) {
        // For iOS 13-14 compatibility, we'll use the older API
        let duration = asset.duration.seconds
        
        // Load metadata asynchronously using older API
        return await withCheckedContinuation { [asset] continuation in
            asset.loadValuesAsynchronously(forKeys: ["duration", "commonMetadata"]) {
                var title: String?
                var artist: String?
                var album: String?
                var artworkData: Data?
                
                // Check if metadata is loaded successfully
                var error: NSError?
                let status = asset.statusOfValue(forKey: "commonMetadata", error: &error)
                guard status == .loaded else {
                    continuation.resume(returning: (nil, nil, nil, duration, nil))
                    return
                }
                
                // Extract metadata
                let metadata = asset.commonMetadata
                for item in metadata {
                    if item.commonKey?.rawValue == "title" {
                        title = item.stringValue
                    } else if item.commonKey?.rawValue == "artist" {
                        artist = item.stringValue
                    } else if item.commonKey?.rawValue == "albumName" {
                        album = item.stringValue
                    } else if item.commonKey?.rawValue == "artwork" {
                        artworkData = item.dataValue
                    }
                }
                
                // If no title is found, use the filename
                if title == nil {
                    let sourceURL = (asset as? AVURLAsset)?.url
                    title = sourceURL?.lastPathComponent
                }
                
                continuation.resume(returning: (title, artist, album, duration, artworkData))
            }
        }
    }
    
    private func updatePlaylistInState(_ playlist: PlaylistItem) async {
        await MainActor.run {
            if let index = self.playlists.firstIndex(where: { $0.id == playlist.id }) {
                self.playlists[index] = playlist
            }
        }
    }
    
    @discardableResult
    func toggleFavorite(_ item: MusicItem) async throws -> MusicItem {
        var music = try await dataProvider.getAllMusic()
        
        // Try to find the music item by ID
        if let index = music.firstIndex(where: { $0.id == item.id }) {
            var updatedItem = music[index]
            updatedItem.isFavorite.toggle()
            music[index] = updatedItem
            
            try await dataProvider.saveMusic(music)
            return updatedItem
        } 
        
        // If not found by ID, try to find by file path
        if let index = music.firstIndex(where: { $0.filePath == item.filePath }) {
            var updatedItem = music[index]
            updatedItem.isFavorite.toggle()
            music[index] = updatedItem
            
            try await dataProvider.saveMusic(music)
            return updatedItem
        }
            
        // If still not found, add the current item to the music library
        var newItem = item
        newItem.isFavorite = true // Directly set as favorite
        music.append(newItem)
        
        try await dataProvider.saveMusic(music)
        return newItem
    }
    
    func getFavorites() async throws -> [MusicItem] {
        let music = try await dataProvider.getAllMusic()
        return music.filter { $0.isFavorite }
    }
    
    @MainActor
    private func setLoading(_ loading: Bool) {
        self.isLoading = loading
    }
    
    @MainActor
    private func setError(_ error: Error?) {
        self.error = error
    }
}
