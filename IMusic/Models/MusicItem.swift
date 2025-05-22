import Foundation
import UIKit

struct MusicItem: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let artist: String?
    let album: String?
    let duration: Double
    let filePath: String // Relative path to the file
    let artworkData: Data?
    let dateAdded: Date
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    static func == (lhs: MusicItem, rhs: MusicItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(id: UUID = UUID(), title: String, artist: String? = nil, album: String? = nil, duration: Double, filePath: String, artworkData: Data? = nil, dateAdded: Date = Date()) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.filePath = filePath
        self.artworkData = artworkData
        self.dateAdded = dateAdded
    }
}
