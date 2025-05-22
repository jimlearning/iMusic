import Foundation

extension FileManager {
    func getDocumentsDirectory() -> URL {
        return urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func getFileSize(for url: URL) -> Int64? {
        do {
            let attributes = try attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
    
    func getFormattedFileSize(for url: URL) -> String {
        guard let size = getFileSize(for: url) else { return "Unknown" }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    func getFileExtension(for url: URL) -> String {
        return url.pathExtension.lowercased()
    }
    
    func isAudioFile(at url: URL) -> Bool {
        let audioExtensions = ["mp3", "wav", "m4a", "aac", "flac", "alac", "aiff"]
        return audioExtensions.contains(getFileExtension(for: url))
    }
    
    func getAudioFiles(in directory: URL) -> [URL] {
        guard let fileURLs = try? contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return fileURLs.filter { isAudioFile(at: $0) }
    }
    
    func copyFileToDocuments(from sourceURL: URL, withName fileName: String? = nil) throws -> URL {
        let documentsDirectory = getDocumentsDirectory()
        let destinationFileName = fileName ?? sourceURL.lastPathComponent
        let destinationURL = documentsDirectory.appendingPathComponent(destinationFileName)
        
        // Check if file already exists
        if fileExists(atPath: destinationURL.path) {
            throw NSError(domain: "FileManager", code: 516, 
                          userInfo: [NSLocalizedDescriptionKey: "A file with this name already exists."])
        }
        
        // Copy the file
        try copyItem(at: sourceURL, to: destinationURL)
        
        return destinationURL
    }
    
    func deleteFile(at url: URL) throws {
        if fileExists(atPath: url.path) {
            try removeItem(at: url)
        } else {
            throw NSError(domain: "FileManager", code: 404, 
                          userInfo: [NSLocalizedDescriptionKey: "File not found."])
        }
    }
}
