import Foundation

struct PlaylistItem: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var musicItems: [MusicItem]
    let dateCreated: Date
    
    var count: Int {
        return musicItems.count
    }
    
    var totalDuration: Double {
        return musicItems.reduce(0) { $0 + $1.duration }
    }
    
    var formattedTotalDuration: String {
        let totalSeconds = Int(totalDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    static func == (lhs: PlaylistItem, rhs: PlaylistItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(id: UUID = UUID(), name: String, musicItems: [MusicItem] = [], dateCreated: Date = Date()) {
        self.id = id
        self.name = name
        self.musicItems = musicItems
        self.dateCreated = dateCreated
    }
}
