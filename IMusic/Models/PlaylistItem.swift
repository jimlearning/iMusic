import Foundation

struct PlaylistItem: Codable, Identifiable, Equatable {
    // Define coding keys to ensure consistent encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case id, name, description, musicItems, dateCreated, category
    }
    let id: UUID
    var name: String
    var description: String
    var musicItems: [MusicItem]
    let dateCreated: Date
    var category: String
    
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
    
    init(id: UUID = UUID(), name: String, description: String = "", musicItems: [MusicItem] = [], dateCreated: Date = Date(), category: String = "") {
        self.id = id
        self.name = name
        self.description = description
        self.musicItems = musicItems
        self.dateCreated = dateCreated
        self.category = category
    }
}
