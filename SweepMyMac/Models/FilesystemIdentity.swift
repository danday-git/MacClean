import Foundation

struct FilesystemIdentity: Hashable, Sendable {
    let canonicalPath: String
    let deviceID: UInt64?
    let inode: UInt64?
    let isSymlink: Bool
    
    init(url: URL) {
        let standardURL = url.standardizedFileURL.resolvingSymlinksInPath()
        let resolved = standardURL.path
        self.canonicalPath = resolved
        
        var statInfo = stat()
        let lstatResult = lstat(url.path, &statInfo)
        
        if lstatResult == 0 {
            self.isSymlink = (statInfo.st_mode & S_IFMT) == S_IFLNK
            self.deviceID = UInt64(statInfo.st_dev)
            self.inode = UInt64(statInfo.st_ino)
        } else {
            self.isSymlink = false
            self.deviceID = nil
            self.inode = nil
        }
    }
    
    init(canonicalPath: String, deviceID: UInt64? = nil, inode: UInt64? = nil, isSymlink: Bool = false) {
        self.canonicalPath = canonicalPath
        self.deviceID = deviceID
        self.inode = inode
        self.isSymlink = isSymlink
    }
    
    func hash(into hasher: inout Hasher) {
        if let dev = deviceID, let ino = inode, !isSymlink {
            hasher.combine(dev)
            hasher.combine(ino)
        } else {
            hasher.combine(canonicalPath)
        }
    }
    
    static func == (lhs: FilesystemIdentity, rhs: FilesystemIdentity) -> Bool {
        if let ldev = lhs.deviceID, let lino = lhs.inode,
           let rdev = rhs.deviceID, let rino = rhs.inode,
           !lhs.isSymlink && !rhs.isSymlink {
            return ldev == rdev && lino == rino
        }
        return lhs.canonicalPath == rhs.canonicalPath
    }
}
