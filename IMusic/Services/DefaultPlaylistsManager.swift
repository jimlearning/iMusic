import Foundation
import AVFoundation

// This class handles the creation and management of default playlists
class DefaultPlaylistsManager {
    
    // Notification name for metadata update completion
    static let metadataUpdateCompletedNotification = Notification.Name("com.imusic.metadataUpdateCompleted")
    
    // Keys to track playlist creation status
    private static let defaultPlaylistsCreatedKey = "com.imusic.defaultPlaylistsCreated"
    private static let playlistVersionKey = "com.imusic.playlistVersion"
    private static let currentPlaylistVersion = 2 // Increment this when making changes to playlist structure
    
    // Category names
    static let recommendedCategory = "推荐"
    static let sleepCategory = "助眠"
    static let relaxCategory = "放松"
    static let focusCategory = "专注"
    
    // Playlist names - Recommended category
    private static let chinesePopPlaylist = "华语流行"
    private static let englishPopPlaylist = "英文热歌"
    private static let nurseryRhymesPlaylist = "儿童歌谣"
    private static let animalSongsPlaylist = "动物歌曲"
    private static let farmSongsPlaylist = "农场歌曲"
    
    // Sleep category
    private static let lullabiesPlaylist = "摇篮曲"
    private static let bedtimePlaylist = "睡前音乐"
    private static let christmasPlaylist = "圣诞歌曲"
    private static let gentleSongsPlaylist = "轻柔歌曲"
    
    // Relax category
    private static let meditationPlaylist = "冥想放松"
    private static let naturePlaylist = "自然之声"
    private static let goodbyeSongsPlaylist = "离别歌曲"
    private static let shapeSongsPlaylist = "认知歌曲"
    
    // Focus category
    private static let studyPlaylist = "学习专注"
    private static let workoutPlaylist = "运动音乐"
    private static let alphabetPlaylist = "字母歌曲"
    private static let countingPlaylist = "数数歌曲"
    
    // Music file categorization - Recommended category
    private static let chinesePopMusic = [
        "天地龙鳞-王力宏.mp3",
        "十年-陈奕迅.flac",
        "四个女生-心愿.flac",
        "千千阙歌-陈慧娴.flac",
        "春天里-汪峰.flac",
        "人间烟火-程响.flac",
    ]
    
    private static let englishPopMusic = [
        "Imagine Dragons–Natural.flac",
        "Baby Shark369.mp3",
        "Five Little Ducks 390.mp3",
    ]
    
    private static let nurseryRhymesMusic = [
        "10 Little Buses 203.mp3",
        "A Sailor Went To Sea314.mp3",
        "Baby Shark369.mp3",
        "The Wheels On The Bus46.mp3",
    ]
    
    private static let animalSongsMusic = [
        "The Animals On The Farm711.mp3",
        "The Bees Go Buzzing122.mp3",
        "The Ants Go Marching #2 .106.mp3",
        "The Itsy Bitsy Spider 545.mp3",
    ]
    
    private static let farmSongsMusic = [
        "The Farmer In The Dell 237.mp3",
        "Down By The Bay208.mp3",
        "The Muffin Man330.mp3",
        "Are You Hungry.mp3",
    ]
    
    // Sleep category
    private static let lullabiesMusic = [
        "远山少年-程奎.mp3",
        "四个女生-心愿.flac",
        "青花瓷-周杰伦.flac",
        "Row Row Row Your Boat 764.mp3",
        "My Teddy Bear573.mp3",
    ]
    
    private static let bedtimeMusic = [
        "美丽的神话-韩红孙楠.mp3",
        "Happy Day–宇珩.flac",
        "The Bath Song508.mp3",
        "Brush Your Teeth341.mp3",
    ]
    
    private static let christmasMusic = [
        "Jingle Bells 729.mp3",
        "What Do You Want For Christmas590.mp3",
        "Pat A Cake 264.mp3",
    ]
    
    private static let gentleSongsMusic = [
        "I Like You325.mp3",
        "Hello Hello504.mp3",
        "The More We Get Together.mp3",
        "The Pinocchio485.mp3",
    ]
    
    // Relax category
    private static let meditationMusic = [
        "笑傲江湖曲-胡伟立.mp3",
        "御龙吟-姚贝娜.mp3",
        "The Jellyfish.mp3",
        "Uh huh 453.mp3",
    ]
    
    private static let natureMusic = [
        "野人-孟维来.flac",
        "Five Little Ducks 390.mp3",
        "Little Robin Redbreast 354.mp3",
        "Here Is The Beehive142.mp3",
    ]
    
    private static let goodbyeSongsMusic = [
        "Goodbye My Friends 458.mp3",
        "Bye Bye Goodbye 449.mp3",
        "Go Away 652.mp3",
        "Say Cheese 499.mp3",
    ]
    
    private static let shapeSongsMusic = [
        "The Shape Song #1.mp3",
        "The Shape Song #2.mp3",
        "The Shape Song #3.mp3",
        "I See Something Pink682.mp3",
    ]
    
    // Focus category
    private static let studyMusic = [
        "平凡之路-朴树.mp3",
        "This Is The Way 405.mp3",
        "Walking Walking 420.mp3",
    ]
    
    private static let workoutMusic = [
        "Yes, I Can 566.mp3",
        "Count Down 582.mp3",
        "Red Light Green Light 150.mp3",
        "Seven Steps 424.mp3",
    ]
    
    private static let alphabetMusic = [
        "The Alphabet Is So Much Fun 296.mp3",
        "The Months Chant749.mp3",
        "Days Of The 413.mp3",
        "Follow Me 233.mp3",
    ]
    
    private static let countingMusic = [
        "One Little Finger 700.mp3",
        "BINGO 757.mp3",
        "How Many Fingers 381.mp3",
        "The Skeleton Dance 397.mp3",
    ]
    
    // Public method to force recreate all playlists
    static func forceRecreateAllPlaylists(musicLibraryService: MusicLibraryService) async {
        // Reset creation flags
        UserDefaults.standard.set(false, forKey: defaultPlaylistsCreatedKey)
        UserDefaults.standard.set(0, forKey: playlistVersionKey)
        
        print("Forcing recreation of all playlists")
        
        // Delete all existing playlists
        do {
            let existingPlaylists = try await musicLibraryService.dataProvider.getPlaylists()
            print("Found \(existingPlaylists.count) existing playlists to remove")
            
            for playlist in existingPlaylists {
                try await musicLibraryService.dataProvider.deletePlaylist(playlist)
                print("Deleted playlist: \(playlist.name)")
            }
            
            // Update in-memory state
            await MainActor.run {
                musicLibraryService.playlists.removeAll()
            }
            
            print("All playlists deleted, now recreating...")
        } catch {
            print("Error while deleting existing playlists: \(error.localizedDescription)")
        }
        
        // Create new playlists
        await createDefaultPlaylists(musicLibraryService: musicLibraryService)
    }
    
    // Create default playlists from bundled resources
    static func createDefaultPlaylists(musicLibraryService: MusicLibraryService) async {
        // Check if default playlists have already been created
        let playlistsCreated = UserDefaults.standard.bool(forKey: defaultPlaylistsCreatedKey)
        
        if playlistsCreated {
            print("Default playlists already created, skipping creation")
            return
        }
        
        print("Creating default playlists")
        
        // Get or create music items
        let musicItems = await getMusicItems(musicLibraryService: musicLibraryService)
        print("Created \(musicItems.count) music items from resources")
        
        // First save all music items to ensure they exist in the data store
        do {
            // Get existing music items
            let existingItems = try await musicLibraryService.dataProvider.getAllMusic()
            
            // Create a new array with existing and new items, avoiding duplicates
            var allItems = existingItems
            for item in musicItems {
                if !allItems.contains(where: { $0.id == item.id }) {
                    allItems.append(item)
                }
            }
            
            // Save all music items
            try await musicLibraryService.dataProvider.saveMusic(allItems)
            print("Saved \(allItems.count) music items to data store")
            
            // Update music items in memory - create a local copy to avoid capturing
            let finalItems = allItems
            await MainActor.run {
                musicLibraryService.musicItems = finalItems
            }
        } catch {
            print("Error saving music items: \(error.localizedDescription)")
        }
        
        // Create recommended category playlists
        await createCategoryPlaylist(name: chinesePopPlaylist, 
                                     category: recommendedCategory,
                                     musicFiles: chinesePopMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        await createCategoryPlaylist(name: englishPopPlaylist, 
                                     category: recommendedCategory,
                                     musicFiles: englishPopMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        await createCategoryPlaylist(name: nurseryRhymesPlaylist, 
                                     category: recommendedCategory,
                                     musicFiles: nurseryRhymesMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        await createCategoryPlaylist(name: animalSongsPlaylist, 
                                     category: recommendedCategory,
                                     musicFiles: animalSongsMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        await createCategoryPlaylist(name: farmSongsPlaylist, 
                                     category: recommendedCategory,
                                     musicFiles: farmSongsMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        // Create sleep category playlists
        await createCategoryPlaylist(name: lullabiesPlaylist, 
                                     category: sleepCategory,
                                     musicFiles: lullabiesMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        await createCategoryPlaylist(name: bedtimePlaylist, 
                                     category: sleepCategory,
                                     musicFiles: bedtimeMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        await createCategoryPlaylist(name: christmasPlaylist, 
                                     category: sleepCategory,
                                     musicFiles: christmasMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        await createCategoryPlaylist(name: gentleSongsPlaylist, 
                                     category: sleepCategory,
                                     musicFiles: gentleSongsMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        // Create relax category playlists
        await createCategoryPlaylist(name: meditationPlaylist, 
                                     category: relaxCategory,
                                     musicFiles: meditationMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        await createCategoryPlaylist(name: naturePlaylist, 
                                     category: relaxCategory,
                                     musicFiles: natureMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        await createCategoryPlaylist(name: goodbyeSongsPlaylist, 
                                     category: relaxCategory,
                                     musicFiles: goodbyeSongsMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        await createCategoryPlaylist(name: shapeSongsPlaylist, 
                                     category: relaxCategory,
                                     musicFiles: shapeSongsMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        // Create focus category playlists
        await createCategoryPlaylist(name: studyPlaylist, 
                                     category: focusCategory,
                                     musicFiles: studyMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        await createCategoryPlaylist(name: workoutPlaylist, 
                                     category: focusCategory,
                                     musicFiles: workoutMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        await createCategoryPlaylist(name: alphabetPlaylist, 
                                     category: focusCategory,
                                     musicFiles: alphabetMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        await createCategoryPlaylist(name: countingPlaylist, 
                                     category: focusCategory,
                                     musicFiles: countingMusic, 
                                     allMusicItems: musicItems,
                                     musicLibraryService: musicLibraryService)
        
        // Mark that default playlists have been created and update version
        UserDefaults.standard.set(true, forKey: defaultPlaylistsCreatedKey)
        UserDefaults.standard.set(currentPlaylistVersion, forKey: playlistVersionKey)
        print("Default playlists creation completed and marked as done (version \(currentPlaylistVersion))")
    }
    
    // Get or create music items in a simpler way - optimized for fast loading
    private static func getMusicItems(musicLibraryService: MusicLibraryService) async -> [MusicItem] {
        // First check if we already have music items in the library
        do {
            let existingItems = try await musicLibraryService.dataProvider.getAllMusic()
            if !existingItems.isEmpty {
                print("Found \(existingItems.count) existing music items")
                
                // Start a background task to update metadata if needed
                let itemsCopy = existingItems // Create a local copy to avoid capture of mutable variable
                Task {
                    await updateMusicItemsMetadata(items: itemsCopy, musicLibraryService: musicLibraryService)
                }
                
                return existingItems
            }
        } catch {
            print("Error checking existing music items: \(error.localizedDescription)")
        }
        
        // If no existing items, quickly create basic music items first
        print("Creating basic music items for fast display")
        var musicItems: [MusicItem] = []
        
        // Combine all music files from all playlists
        let allMusicFiles = chinesePopMusic + englishPopMusic + nurseryRhymesMusic + animalSongsMusic + farmSongsMusic +
                          lullabiesMusic + bedtimeMusic + christmasMusic + gentleSongsMusic +
                          meditationMusic + natureMusic + goodbyeSongsMusic + shapeSongsMusic +
                          studyMusic + workoutMusic + alphabetMusic + countingMusic
        
        // Create basic music items with minimal information for fast loading
        for musicFile in allMusicFiles {
            let fileName = URL(fileURLWithPath: musicFile).lastPathComponent
            let fileNameWithoutExt = URL(fileURLWithPath: musicFile).deletingPathExtension().lastPathComponent
            
            // Create a basic music item with just the essential information
            let musicItem = MusicItem(
                id: UUID(),
                title: fileNameWithoutExt,
                artist: "Loading...",
                album: "Loading...",
                duration: 180.0, // Default 3 minutes
                filePath: fileName,
                artworkData: nil
            )
            
            musicItems.append(musicItem)
        }
        
        // Save the basic music items
        do {
            try await musicLibraryService.dataProvider.saveMusic(musicItems)
            print("Saved \(musicItems.count) basic music items")
            
            // Start a background task to load detailed metadata
            let itemsCopy = musicItems // Create a local copy to avoid capture of mutable variable
            Task {
                await updateMusicItemsMetadata(items: itemsCopy, musicLibraryService: musicLibraryService)
            }
            
        } catch {
            print("Error saving basic music items: \(error.localizedDescription)")
        }
        
        return musicItems
    }
    
    // Update music items with detailed metadata in background
    private static func updateMusicItemsMetadata(items: [MusicItem], musicLibraryService: MusicLibraryService) async {
        print("Starting background metadata update for \(items.count) items")
        let fileManager = FileManager.default
        var updatedItems: [MusicItem] = []
        
        for item in items {
            // Skip items that already have complete metadata
            if item.artist != "Loading..." && item.artist != "Unknown Artist" && item.artworkData != nil {
                continue
            }
            
            let fileName = item.filePath
            let fileNameWithoutExt = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
            
            // Check if file exists in bundle
            var fileURL: URL? = nil
            let possibleExtensions = ["mp3", "m4a", "wav", "aac", "flac"]
            
            // Try to find the file with the exact name
            if let url = Bundle.main.url(forResource: fileNameWithoutExt, withExtension: URL(fileURLWithPath: fileName).pathExtension) {
                fileURL = url
            } else {
                // Try different extensions if exact match not found
                for ext in possibleExtensions {
                    if let url = Bundle.main.url(forResource: fileNameWithoutExt, withExtension: ext) {
                        fileURL = url
                        break
                    }
                }
            }
            
            // If file found, copy to documents directory and extract metadata
            if let sourceURL = fileURL {
                let destinationURL = musicLibraryService.documentDirectory.appendingPathComponent(fileName)
                
                // Copy file if it doesn't exist in documents directory
                if !fileManager.fileExists(atPath: destinationURL.path) {
                    do {
                        try fileManager.copyItem(at: sourceURL, to: destinationURL)
                    } catch {
                        print("Error copying file \(fileName): \(error.localizedDescription)")
                    }
                }
                
                // Extract metadata from the audio file
                do {
                    let asset = AVAsset(url: destinationURL)
                    let metadata = try await extractMetadata(from: asset)
                    
                    // Create updated music item with extracted metadata
                    let updatedItem = MusicItem(
                        id: item.id, // Keep the same ID
                        title: metadata.title ?? fileNameWithoutExt,
                        artist: metadata.artist ?? "Unknown Artist",
                        album: metadata.album ?? "Unknown Album",
                        duration: metadata.duration,
                        filePath: fileName,
                        artworkData: metadata.artworkData
                    )
                    
                    updatedItems.append(updatedItem)
                } catch {
                    print("Error extracting metadata from \(fileName): \(error.localizedDescription)")
                    
                    // Create a basic music item if metadata extraction fails
                    let updatedItem = MusicItem(
                        id: item.id, // Keep the same ID
                        title: item.title,
                        artist: "Unknown Artist",
                        album: "Unknown Album",
                        duration: 180.0,
                        filePath: fileName,
                        artworkData: nil
                    )
                    
                    updatedItems.append(updatedItem)
                }
            } else {
                // Update with basic info if file not found
                let updatedItem = MusicItem(
                    id: item.id, // Keep the same ID
                    title: item.title,
                    artist: "Unknown Artist",
                    album: "Unknown Album",
                    duration: 180.0,
                    filePath: item.filePath,
                    artworkData: nil
                )
                
                updatedItems.append(updatedItem)
            }
        }
        
        // If we have updated items, save them
        if !updatedItems.isEmpty {
            do {
                // Get all current music items
                let allItems = try await musicLibraryService.dataProvider.getAllMusic()
                
                // Create a new array with updated items replacing old ones
                var newItems: [MusicItem] = []
                for item in allItems {
                    if let updatedIndex = updatedItems.firstIndex(where: { $0.id == item.id }) {
                        newItems.append(updatedItems[updatedIndex])
                    } else {
                        newItems.append(item)
                    }
                }
                
                // Save the updated items
                try await musicLibraryService.dataProvider.saveMusic(newItems)
                print("Updated \(updatedItems.count) music items with detailed metadata")
                
                // Update playlists to use the new items
                await updatePlaylistsWithNewItems(updatedItems: updatedItems, musicLibraryService: musicLibraryService)
                
            } catch {
                print("Error saving updated music items: \(error.localizedDescription)")
            }
        }
    }
    
    // Update playlists with the new items
    private static func updatePlaylistsWithNewItems(updatedItems: [MusicItem], musicLibraryService: MusicLibraryService) async {
        do {
            // Get all playlists
            let playlists = try await musicLibraryService.dataProvider.getPlaylists()
            var updatedPlaylists: [PlaylistItem] = []
            var playlistsChanged = false
            
            // Update each playlist
            for playlist in playlists {
                var newMusicItems = playlist.musicItems
                var playlistChanged = false
                
                // Replace items with updated versions
                for (index, item) in playlist.musicItems.enumerated() {
                    if let updatedItem = updatedItems.first(where: { $0.id == item.id }) {
                        newMusicItems[index] = updatedItem
                        playlistChanged = true
                    }
                }
                
                if playlistChanged {
                    let updatedPlaylist = PlaylistItem(
                        id: playlist.id,
                        name: playlist.name,
                        description: playlist.description,
                        musicItems: newMusicItems,
                        dateCreated: playlist.dateCreated,
                        category: playlist.category
                    )
                    updatedPlaylists.append(updatedPlaylist)
                    playlistsChanged = true
                } else {
                    updatedPlaylists.append(playlist)
                }
            }
            
            // Save updated playlists if any changed
            if playlistsChanged {
                try await musicLibraryService.dataProvider.savePlaylists(updatedPlaylists)
                print("Updated playlists with new music item metadata")
                
                // Update in-memory playlists
                let finalPlaylists = updatedPlaylists // Create a local copy to avoid capture of mutable variable
                await MainActor.run {
                    musicLibraryService.playlists = finalPlaylists
                    
                    // Post notification that metadata update is completed
                    NotificationCenter.default.post(name: metadataUpdateCompletedNotification, object: nil)
                }
            }
        } catch {
            print("Error updating playlists with new items: \(error.localizedDescription)")
        }
    }

    // Create a category playlist with the given name, category and music items
    private static func createCategoryPlaylist(name: String, 
                                              category: String,
                                              musicFiles: [String], 
                                              allMusicItems: [MusicItem],
                                              musicLibraryService: MusicLibraryService) async {
        // Skip if playlist already exists
        if musicLibraryService.playlists.contains(where: { $0.name == name }) {
            return
        }
        
        // Find matching music items for this playlist
        var playlistItems: [MusicItem] = []
        
        // Simple matching algorithm: find items whose filename contains the music file name or vice versa
        for musicFile in musicFiles {
            let targetName = URL(fileURLWithPath: musicFile).deletingPathExtension().lastPathComponent.lowercased()
            
            // Find matching items
            let matches = allMusicItems.filter { item in
                let itemName = URL(fileURLWithPath: item.filePath).deletingPathExtension().lastPathComponent.lowercased()
                return itemName.contains(targetName) || targetName.contains(itemName)
            }
            
            if let match = matches.first {
                playlistItems.append(match)
            }
        }
        
        // If no matches found, add some random items to ensure playlist has content
        if playlistItems.isEmpty && !allMusicItems.isEmpty {
            let count = min(5, allMusicItems.count)
            for i in 0..<count {
                playlistItems.append(allMusicItems[i])
            }
        }
        
        // Create the playlist
        let playlist = PlaylistItem(
            id: UUID(),
            name: name,
            description: "A collection of \(name) music",
            musicItems: playlistItems,
            dateCreated: Date(),
            category: category
        )
        
        // Save the playlist
        do {
            // Get current playlists
            let existingPlaylists = try await musicLibraryService.dataProvider.getPlaylists()
            
            // Add new playlist
            var updatedPlaylists = existingPlaylists
            updatedPlaylists.append(playlist)
            
            // Save all playlists
            try await musicLibraryService.dataProvider.savePlaylists(updatedPlaylists)
            
            // Update in-memory state
            await MainActor.run {
                musicLibraryService.playlists.append(playlist)
            }
        } catch {
            print("Error creating playlist \(name): \(error.localizedDescription)")
        }
    }
    
    // Extract metadata from audio asset
    private static func extractMetadata(from asset: AVAsset) async throws -> (title: String?, artist: String?, album: String?, duration: Double, artworkData: Data?) {
        // For iOS 13-14 compatibility, we'll use the older API
        let duration = asset.duration.seconds
        
        // Load metadata asynchronously using older API
        return await withCheckedContinuation { continuation in
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
}

// Helper extensions for file path handling
extension String {
    // Helper to get path without extension
    var deletingPathExtension: String {
        return URL(fileURLWithPath: self).deletingPathExtension().lastPathComponent
    }
    
    // Helper to get path extension
    var pathExtension: String {
        return URL(fileURLWithPath: self).pathExtension
    }
}
