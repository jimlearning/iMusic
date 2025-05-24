import Foundation

struct UserSettings: Codable {
    var sortOption: SortOption
    var repeatMode: RepeatMode
    var shuffleEnabled: Bool
    var equalizerEnabled: Bool
    var equalizerPreset: EqualizerPreset
    var volume: Float
    var lastPlayedMusicItem: MusicItem?
    var lastPlaybackPosition: TimeInterval
    var themeMode: ThemeMode
    
    init(sortOption: SortOption = .title, 
         repeatMode: RepeatMode = .none, 
         shuffleEnabled: Bool = false, 
         equalizerEnabled: Bool = false, 
         equalizerPreset: EqualizerPreset = .flat,
         volume: Float = 0.5,
         lastPlayedMusicItem: MusicItem? = nil,
         lastPlaybackPosition: TimeInterval = 0,
         themeMode: ThemeMode = .system) {
        self.sortOption = sortOption
        self.repeatMode = repeatMode
        self.shuffleEnabled = shuffleEnabled
        self.equalizerEnabled = equalizerEnabled
        self.equalizerPreset = equalizerPreset
        self.volume = volume
        self.lastPlayedMusicItem = lastPlayedMusicItem
        self.lastPlaybackPosition = lastPlaybackPosition
        self.themeMode = themeMode
    }
}

enum SortOption: String, Codable, CaseIterable {
    case dateAdded = "添加日期"
    case title = "标题"
    case artist = "艺术家"
    case album = "专辑"
    case duration = "时长"
}

enum RepeatMode: Int, Codable, CaseIterable {
    case none = 0
    case all = 1
    case one = 2
}

enum ThemeMode: Int, Codable, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2
    
    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}

enum EqualizerPreset: String, Codable, CaseIterable {
    case flat = "平衡"
    case bass = "低音增强"
    case treble = "高音增强"
    case vocal = "人声增强"
    case electronic = "电子音乐"
    case rock = "摇滚音乐"
    case pop = "流行音乐"
    case jazz = "爵士音乐"
    case classical = "古典音乐"
    case custom = "自定义"
}
