import Foundation

/// Extract all the contents of a .7z archive directly into the indicated dir.
///
/// - parameter archivePath: path to the .7z archive.
/// - parameter dirname:     dir to extract to (will be created)
/// - parameter preserveDir: Directory structure is ignored if preserveDir is false.
///
/// - returns: a list of extracted files
public func extract7zArchive(archivePath: String, dirName: String, preserveDir: Bool) -> [String] {
    return LZMAExtractor.extract7zArchive(archivePath, dirName: dirName, preserveDir: preserveDir).map { $0 as! String }
}

/// Extract just one entry from an archive and save it at the
/// path indicated by outPath.
///
/// - parameter archivePath: path to the .7z archive.
/// - parameter archiveEntry:   the entry to extract
/// - parameter outPath:        directory to extract to
///
/// - returns: true if successful
public func extract7zArchiveEntry(archivePath: String, archiveEntry: String, outPath: String) -> Bool {
    return LZMAExtractor.extractArchiveEntry(archivePath, archiveEntry: archiveEntry, outPath: outPath)
}
