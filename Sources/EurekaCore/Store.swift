import Foundation

public enum ProgressStoreError: Error, Equatable {
    case unwritable(String)
}

private struct ProgressEnvelope: Codable, Equatable {
    var version: Int
    var progress: PlayerProgress

    static let currentVersion = 1
}

public struct ProgressStore {
    public var directory: URL
    public var fileManager: FileManager

    public init(directory: URL, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
    }

    public var fileURL: URL {
        directory.appendingPathComponent("progress.json")
    }

    public var backupURL: URL {
        directory.appendingPathComponent("progress.json.bak")
    }

    /// A missing file is a new player. A broken file is set aside so the app
    /// still opens, and the next save writes a fresh progress file.
    public func load() -> PlayerProgress {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return .fresh
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let envelope = try JSONDecoder().decode(ProgressEnvelope.self, from: data)
            return envelope.progress
        } catch {
            quarantineCorruptFile()
            return .fresh
        }
    }

    public func save(_ progress: PlayerProgress) throws {
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            var data = try encoder.encode(ProgressEnvelope(version: ProgressEnvelope.currentVersion, progress: progress))
            data.append(0x0A)
            try writeAtomically(data, to: fileURL)
        } catch {
            throw ProgressStoreError.unwritable(error.localizedDescription)
        }
    }

    private func quarantineCorruptFile() {
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.removeItem(at: backupURL)
            }
            try fileManager.moveItem(at: fileURL, to: backupURL)
        } catch {
            // Leave the unreadable file in place. The next launch tries again.
        }
    }

    private func writeAtomically(_ data: Data, to url: URL) throws {
        let folder = url.deletingLastPathComponent()
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        let temp = folder.appendingPathComponent(".\(url.lastPathComponent).\(UUID().uuidString).tmp")
        try data.write(to: temp, options: .atomic)
        if fileManager.fileExists(atPath: url.path) {
            _ = try fileManager.replaceItemAt(url, withItemAt: temp)
        } else {
            try fileManager.moveItem(at: temp, to: url)
        }
    }
}
