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

    private var playlistsDataURL: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("playlistsData.json")
    }
    private let settingsKey = "com.imusic.userSettings"

    private let fileManager = FileManager.default
    private var musicDataURL: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("musicData.json")
    }
    
    func getAllMusic() async throws -> [MusicItem] {
        if fileManager.fileExists(atPath: musicDataURL.path) {
            do {
                let data = try Data(contentsOf: musicDataURL)
                let items = try JSONDecoder().decode([MusicItem].self, from: data)
                return items
            } catch {
                // If there's an error with the file, try to delete it
                try? fileManager.removeItem(at: musicDataURL)
                return []
            }
        }
        
        return []
    }
    
    func getPlaylists() async throws -> [PlaylistItem] {
        if fileManager.fileExists(atPath: playlistsDataURL.path) {
            do {
                let data = try Data(contentsOf: playlistsDataURL)
                let playlists = try JSONDecoder().decode([PlaylistItem].self, from: data)
                return playlists
            } catch {
                // If there's an error with the file, try to delete it
                try? fileManager.removeItem(at: playlistsDataURL)
                return []
            }
        }
        
        return []
    }
    
    func saveMusic(_ items: [MusicItem]) async throws {
        let data = try JSONEncoder().encode(items)
        try data.write(to: musicDataURL, options: .atomic)
    }
    
    func savePlaylists(_ playlists: [PlaylistItem]) async throws {
        let data = try JSONEncoder().encode(playlists)
        try data.write(to: playlistsDataURL, options: .atomic)
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
            do {
                return try JSONDecoder().decode(UserSettings.self, from: data)
            } catch {
                print("Error decoding user settings: \(error), returning default settings")
                // 如果解码失败，清除旧的设置并返回默认设置
                userDefaults.removeObject(forKey: settingsKey)
                return UserSettings()
            }
        }
        return UserSettings()
    }
    
    func saveUserSettings(_ settings: UserSettings) async throws {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(settings)
            userDefaults.set(data, forKey: settingsKey)
            userDefaults.synchronize() // 确保立即写入
            
            // 验证数据是否正确保存
            if let savedData = userDefaults.data(forKey: settingsKey) {
                let decoder = JSONDecoder()
                let loadedSettings = try decoder.decode(UserSettings.self, from: savedData)
                print("Verification successful: Saved settings with lastPlayedMusicItem: \(loadedSettings.lastPlayedMusicItem?.title ?? "none")")
            }
        } catch {
            print("Error in saveUserSettings: \(error)")
            throw error
        }
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
