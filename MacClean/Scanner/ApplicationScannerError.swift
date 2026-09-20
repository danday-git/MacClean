import Foundation

enum ApplicationScannerError: Error, LocalizedError {
    case directoryInaccessible(URL)
    
    var errorDescription: String? {
        switch self {
        case .directoryInaccessible(let url):
            return "Could not access application directory at \(url.path)."
        }
    }
}
