import Foundation
import AVFoundation

// This class handles the creation and management of default playlists
class DefaultPlaylistsManager {
    
    // Key to track if default playlists have been created
    private static let defaultPlaylistsCreatedKey = "com.imusic.defaultPlaylistsCreated"
    
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
    private static let goodbyeSongsPlaylist = "告别歌曲"
    private static let shapeSongsPlaylist = "形状歌曲"
    
    // Focus category
    private static let studyPlaylist = "学习专注"
    private static let workoutPlaylist = "运动音乐"
    private static let alphabetPlaylist = "字母歌曲"
    private static let countingPlaylist = "数数歌曲"
    
    // Music file categorization - Recommended category
    private static let chinesePopMusic = [
        "十年-陈奕迅.flac",
        "青花瓷-周杰伦.flac",
        "春天里-汪峰.flac",
        "人间烟火-程响.flac",
    ]
    
    private static let englishPopMusic = [
        "Imagine Dragons–Natural.flac",
        "When The Band Comes Marching In 133.mp3",
        "Take Me Out To The Ball Game275.mp3",
        "远山少年-程奎.mp3",
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
        "四个女生-心愿.flac",
        "千千阙歌-陈慧娴.flac",
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
        "Pat-A-Cake 264.mp3",
    ]
    
    private static let gentleSongsMusic = [
        "I Like You325.mp3",
        "Hello Hello504.mp3",
        "The More We Get Together.mp3",
        "The Pinocchio485.mp3",
    ]
    
    // Relax category
    private static let meditationMusic = [
        "御龙吟-姚贝娜.mp3",
        "笑傲江湖曲-胡伟立.mp3",
        "The Jellyfish.mp3",
        "Uh-huh! 453.mp3",
    ]
    
    private static let natureMusic = [
        "野人-孟维来.flac",
        "Five Little Ducks 390.mp3",
        "Little Robin Redbreast 354.mp3",
        "Here Is The Beehive142.mp3",
    ]
    
    private static let goodbyeSongsMusic = [
        "Goodbye, My Friends458.mp3",
        "Bye Bye Goodbye 449.mp3",
        "Go Away 652.mp3",
        "Say Cheese!499.mp3",
    ]
    
    private static let shapeSongsMusic = [
        "The Shape Song #1.mp3",
        "The Shape Song #1518.mp3",
        "The Shape Song #2 531.mp3",
        "I See Something Pink682.mp3",
    ]
    
    // Focus category
    private static let studyMusic = [
        "平凡之路-朴树.mp3",
        "天地龙鳞-王力宏.mp3",
        "This Is The Way 405.mp3",
        "Walking Walking 420.mp3",
    ]
    
    private static let workoutMusic = [
        "Yes, I Can! 566.mp3",
        "Count Down 582.mp3",
        "Red Light, Green Light150.mp3",
        "Seven Steps _424.mp3",
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
        "How Many Fingers_381.mp3",
        "The Skeleton Dance 397.mp3",
    ]
    
    // Create default playlists from bundled resources
    static func createDefaultPlaylists(musicLibraryService: MusicLibraryService) async {
        // Check if default playlists have already been created
        if UserDefaults.standard.bool(forKey: defaultPlaylistsCreatedKey) {
            print("Default playlists already created, skipping creation")
            return
        }
        
        print("Starting default playlists creation")
        
        // Get the resource directory URL
        guard let resourceURL = Bundle.main.resourceURL else {
            print("Failed to get resource URL")
            return
        }
        
        // Create music items from resources
        let musicItems = await createMusicItemsFromResources(resourceURL: resourceURL, musicLibraryService: musicLibraryService)
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
        
        // Mark that default playlists have been created
        UserDefaults.standard.set(true, forKey: defaultPlaylistsCreatedKey)
        print("Default playlists creation completed and marked as done")
    }
    
    // Create music items from resource files
    private static func createMusicItemsFromResources(resourceURL: URL, musicLibraryService: MusicLibraryService) async -> [MusicItem] {
        var musicItems: [MusicItem] = []
        
        // Get all music files from resources
        let resourcesDirectory = resourceURL.appendingPathComponent("Resources")
        print("Looking for music files in: \(resourcesDirectory.path)")
        
        // Check if directory exists
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: resourcesDirectory.path, isDirectory: &isDirectory) || !isDirectory.boolValue {
            print("Resources directory does not exist at path: \(resourcesDirectory.path)")
            
            // Try to look directly in the bundle
            print("Trying to access music files directly from bundle")
            let bundle = Bundle.main
            // Combine all music files from all playlists
            let allMusicFiles = chinesePopMusic + englishPopMusic + lullabiesMusic + bedtimeMusic + 
                              meditationMusic + natureMusic + studyMusic + workoutMusic + 
                              nurseryRhymesMusic + christmasMusic
            
            for musicFile in allMusicFiles {
                let filename = URL(fileURLWithPath: musicFile).deletingPathExtension().lastPathComponent
                let fileExtension = URL(fileURLWithPath: musicFile).pathExtension
                if let fileURL = bundle.url(forResource: filename, withExtension: fileExtension) {
                    do {
                        let musicItem = try await importResourceMusic(fileURL: fileURL, musicLibraryService: musicLibraryService)
                        musicItems.append(musicItem)
                        print("Successfully imported: \(musicFile)")
                    } catch {
                        print("Error importing \(musicFile): \(error.localizedDescription)")
                    }
                } else {
                    print("Could not find resource: \(musicFile)")
                }
            }
            
            return musicItems
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: resourcesDirectory, 
                                                                       includingPropertiesForKeys: nil)
            print("Found \(fileURLs.count) files in resources directory")
            
            // Process each music file
            for fileURL in fileURLs {
                if fileURL.pathExtension == "mp3" || fileURL.pathExtension == "flac" {
                    do {
                        // Copy the file to documents directory
                        let musicItem = try await importResourceMusic(fileURL: fileURL, musicLibraryService: musicLibraryService)
                        musicItems.append(musicItem)
                    } catch {
                        print("Error importing resource music: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            print("Error accessing resources directory: \(error.localizedDescription)")
        }
        
        return musicItems
    }
    
    // Import a single music file from resources
    private static func importResourceMusic(fileURL: URL, musicLibraryService: MusicLibraryService) async throws -> MusicItem {
        let fileName = fileURL.lastPathComponent
        let destinationURL = musicLibraryService.documentDirectory.appendingPathComponent(fileName)
        
        print("Importing music file: \(fileName)")
        
        // Check if file already exists in documents directory
        if !FileManager.default.fileExists(atPath: destinationURL.path) {
            print("Copying file to documents directory: \(destinationURL.path)")
            try FileManager.default.copyItem(at: fileURL, to: destinationURL)
        } else {
            print("File already exists in documents directory")
        }
        
        // Extract metadata
        let asset = AVAsset(url: destinationURL)
        let metadata = try await extractMetadata(from: asset)
        
        // Create music item
        let musicItem = MusicItem(
            title: metadata.title ?? fileName,
            artist: metadata.artist,
            album: metadata.album,
            duration: metadata.duration,
            filePath: fileName,
            artworkData: metadata.artworkData
        )
        
        return musicItem
    }
    
    // Create a category playlist
    private static func createCategoryPlaylist(name: String, 
                                              category: String,
                                              musicFiles: [String], 
                                              allMusicItems: [MusicItem],
                                              musicLibraryService: MusicLibraryService) async {
        print("Creating \(name) playlist with \(musicFiles.count) specified files")
        
        // Find music items for this category
        var categoryItems: [MusicItem] = []
        
        for musicFile in musicFiles {
            // Try to find a match by filename
            let matchingItems = allMusicItems.filter { item in
                // Get just the filename without extension for comparison
                let itemBaseName = URL(fileURLWithPath: item.filePath).deletingPathExtension().lastPathComponent.lowercased()
                let targetBaseName = URL(fileURLWithPath: musicFile).deletingPathExtension().lastPathComponent.lowercased()
                
                // Check if either contains the other or if they're similar enough
                let itemContainsTarget = itemBaseName.contains(targetBaseName)
                let targetContainsItem = targetBaseName.contains(itemBaseName)
                
                // For debugging
                if itemContainsTarget || targetContainsItem {
                    print("Match found: Item='\(itemBaseName)' Target='\(targetBaseName)'")
                }
                
                return itemContainsTarget || targetContainsItem
            }
            
            if let match = matchingItems.first {
                print("Found matching music item: \(match.title) (\(match.filePath)) for \(musicFile)")
                categoryItems.append(match)
            } else {
                print("No match found for: \(musicFile)")
            }
        }
        
        print("Found \(categoryItems.count) matching items for \(name) playlist out of \(musicFiles.count) specified files")
        
        // Check if playlist already exists
        if !musicLibraryService.playlists.contains(where: { $0.name == name }) {
            print("Creating new playlist: \(name) with \(categoryItems.count) items")
            
            // Create new playlist with all required fields explicitly set
            let playlist = PlaylistItem(
                id: UUID(),
                name: name,
                description: "A collection of \(name) music",
                musicItems: categoryItems,
                dateCreated: Date(),
                category: category
            )
            
            print("Created playlist: id=\(playlist.id), name=\(playlist.name), description=\(playlist.description), items=\(playlist.musicItems.count)")
            
            // Verify playlist can be encoded/decoded before saving
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(playlist)
                let decoder = JSONDecoder()
                let _ = try decoder.decode(PlaylistItem.self, from: data)
                print("Playlist encoding/decoding test successful")
            } catch {
                print("Playlist encoding/decoding test failed: \(error)")
            }
            
            // Save playlist
            do {
                // Get current playlists
                let existingPlaylists = try await musicLibraryService.dataProvider.getPlaylists()
                print("Retrieved \(existingPlaylists.count) existing playlists")
                
                // Create a new array with existing playlists plus the new one
                var updatedPlaylists = existingPlaylists
                updatedPlaylists.append(playlist)
                
                // Save all playlists
                try await musicLibraryService.dataProvider.savePlaylists(updatedPlaylists)
                print("Successfully saved \(updatedPlaylists.count) playlists")
                
                // Create a local copy of the playlist to avoid capturing
                let newPlaylist = playlist
                
                // Update local state
                await MainActor.run {
                    musicLibraryService.playlists.append(newPlaylist)
                    print("Updated in-memory playlists, now have \(musicLibraryService.playlists.count) playlists")
                }
            } catch {
                print("Error creating \(name) playlist: \(error.localizedDescription)")
                print("Error details: \(error)")
            }
        } else {
            print("Playlist \(name) already exists, skipping creation")
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
