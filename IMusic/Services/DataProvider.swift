import Foundation

protocol DataProvider {
    func getAllMusic() async throws -> [MusicItem]
    func getPlaylists() async throws -> [PlaylistItem]
    func saveMusic(_ items: [MusicItem]) async throws
    func savePlaylists(_ playlists: [PlaylistItem]) async throws
    func deleteMusic(_ item: MusicItem) async throws
    func deletePlaylist(_ playlist: PlaylistItem) async throws
    func addMusicToPlaylist(_ music: MusicItem, playlist: PlaylistItem) async throws -> PlaylistItem
    func removeMusicFromPlaylist(_ music: MusicItem, playlist: PlaylistItem) async throws -> PlaylistItem
    func createPlaylist(name: String, items: [MusicItem]) async throws -> PlaylistItem
    func updatePlaylist(_ playlist: PlaylistItem) async throws
    func getUserSettings() async throws -> UserSettings
    func saveUserSettings(_ settings: UserSettings) async throws
}

class LocalDataProvider: DataProvider {
    private let userDefaults = UserDefaults.standard
    private let musicKey = "com.imusic.storedMusic"
    private let playlistsKey = "com.imusic.storedPlaylists"
    private let settingsKey = "com.imusic.userSettings"
    
    func getAllMusic() async throws -> [MusicItem] {
        if let data = userDefaults.data(forKey: musicKey) {
            return try JSONDecoder().decode([MusicItem].self, from: data)
        }
        return []
    }
    
    func getPlaylists() async throws -> [PlaylistItem] {
        if let data = userDefaults.data(forKey: playlistsKey) {
            do {
                let decoder = JSONDecoder()
                return try decoder.decode([PlaylistItem].self, from: data)
            } catch {
                print("Error decoding playlists: \(error)")
                // If there's an error with the existing data, return an empty array
                // and clear the corrupted data
                userDefaults.removeObject(forKey: playlistsKey)
                return []
            }
        }
        return []
    }
    
    func saveMusic(_ items: [MusicItem]) async throws {
        let data = try JSONEncoder().encode(items)
        userDefaults.set(data, forKey: musicKey)
    }
    
    func savePlaylists(_ playlists: [PlaylistItem]) async throws {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(playlists)
            userDefaults.set(data, forKey: playlistsKey)
            print("Successfully saved \(playlists.count) playlists to UserDefaults")
            
            // Verify data can be decoded
            if let savedData = userDefaults.data(forKey: playlistsKey) {
                let decoder = JSONDecoder()
                let decodedPlaylists = try decoder.decode([PlaylistItem].self, from: savedData)
                print("Verification successful: Decoded \(decodedPlaylists.count) playlists")
            }
        } catch {
            print("Error in savePlaylists: \(error)")
            throw error
        }
    }
    
    func deleteMusic(_ item: MusicItem) async throws {
        var music = try await getAllMusic()
        music.removeAll { $0.id == item.id }
        try await saveMusic(music)
        
        // Also remove from playlists
        var playlists = try await getPlaylists()
        for i in 0..<playlists.count {
            playlists[i].musicItems.removeAll { $0.id == item.id }
        }
        try await savePlaylists(playlists)
    }
    
    func deletePlaylist(_ playlist: PlaylistItem) async throws {
        var playlists = try await getPlaylists()
        playlists.removeAll { $0.id == playlist.id }
        try await savePlaylists(playlists)
    }
    
    func addMusicToPlaylist(_ music: MusicItem, playlist: PlaylistItem) async throws -> PlaylistItem {
        var playlists = try await getPlaylists()
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else {
            throw NSError(domain: "LocalDataProvider", code: 404, userInfo: [NSLocalizedDescriptionKey: "Playlist not found"])
        }
        
        if !playlists[index].musicItems.contains(where: { $0.id == music.id }) {
            playlists[index].musicItems.append(music)
            try await savePlaylists(playlists)
        }
        
        return playlists[index]
    }
    
    func removeMusicFromPlaylist(_ music: MusicItem, playlist: PlaylistItem) async throws -> PlaylistItem {
        var playlists = try await getPlaylists()
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else {
            throw NSError(domain: "LocalDataProvider", code: 404, userInfo: [NSLocalizedDescriptionKey: "Playlist not found"])
        }
        
        playlists[index].musicItems.removeAll { $0.id == music.id }
        try await savePlaylists(playlists)
        
        return playlists[index]
    }
    
    func createPlaylist(name: String, items: [MusicItem] = []) async throws -> PlaylistItem {
        var playlists = try await getPlaylists()
        let newPlaylist = PlaylistItem(name: name, musicItems: items)
        playlists.append(newPlaylist)
        try await savePlaylists(playlists)
        return newPlaylist
    }
    
    func updatePlaylist(_ playlist: PlaylistItem) async throws {
        var playlists = try await getPlaylists()
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else {
            throw NSError(domain: "LocalDataProvider", code: 404, userInfo: [NSLocalizedDescriptionKey: "Playlist not found"])
        }
        
        playlists[index] = playlist
        try await savePlaylists(playlists)
    }
    
    func getUserSettings() async throws -> UserSettings {
        if let data = userDefaults.data(forKey: settingsKey) {
            return try JSONDecoder().decode(UserSettings.self, from: data)
        }
        return UserSettings()
    }
    
    func saveUserSettings(_ settings: UserSettings) async throws {
        let data = try JSONEncoder().encode(settings)
        userDefaults.set(data, forKey: settingsKey)
    }
}

// 预留网络数据提供者的接口实现
class NetworkDataProvider: DataProvider {
    // 这里是网络数据提供者的实现，目前仅作为占位符
    // 实际项目中，这里会实现真正的网络请求逻辑
    
    func getAllMusic() async throws -> [MusicItem] {
        // 模拟网络请求延迟
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return []
    }
    
    func getPlaylists() async throws -> [PlaylistItem] {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return []
    }
    
    func saveMusic(_ items: [MusicItem]) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func savePlaylists(_ playlists: [PlaylistItem]) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func deleteMusic(_ item: MusicItem) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func deletePlaylist(_ playlist: PlaylistItem) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func addMusicToPlaylist(_ music: MusicItem, playlist: PlaylistItem) async throws -> PlaylistItem {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return playlist
    }
    
    func removeMusicFromPlaylist(_ music: MusicItem, playlist: PlaylistItem) async throws -> PlaylistItem {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return playlist
    }
    
    func createPlaylist(name: String, items: [MusicItem] = []) async throws -> PlaylistItem {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return PlaylistItem(name: name, musicItems: items)
    }
    
    func updatePlaylist(_ playlist: PlaylistItem) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func getUserSettings() async throws -> UserSettings {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return UserSettings()
    }
    
    func saveUserSettings(_ settings: UserSettings) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
}
