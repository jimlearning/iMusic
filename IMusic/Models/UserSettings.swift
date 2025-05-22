import Foundation

struct UserSettings: Codable {
    var sortOption: SortOption
    var repeatMode: RepeatMode
    var shuffleEnabled: Bool
    var equalizerEnabled: Bool
    var equalizerPreset: EqualizerPreset
    var volume: Float
    
    init(sortOption: SortOption = .title, 
         repeatMode: RepeatMode = .none, 
         shuffleEnabled: Bool = false, 
         equalizerEnabled: Bool = false, 
         equalizerPreset: EqualizerPreset = .flat, 
         volume: Float = 0.7) {
        self.sortOption = sortOption
        self.repeatMode = repeatMode
        self.shuffleEnabled = shuffleEnabled
        self.equalizerEnabled = equalizerEnabled
        self.equalizerPreset = equalizerPreset
        self.volume = volume
    }
}

enum SortOption: String, Codable, CaseIterable {
    case title = "Title"
    case artist = "Artist"
    case album = "Album"
    case dateAdded = "Date Added"
    case duration = "Duration"
}

enum RepeatMode: Int, Codable, CaseIterable {
    case none = 0
    case all = 1
    case one = 2
}

enum EqualizerPreset: String, Codable, CaseIterable {
    case flat = "Flat"
    case bass = "Bass Boost"
    case treble = "Treble Boost"
    case vocal = "Vocal Boost"
    case electronic = "Electronic"
    case rock = "Rock"
    case pop = "Pop"
    case jazz = "Jazz"
    case classical = "Classical"
    case custom = "Custom"
}
