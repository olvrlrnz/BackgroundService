import Foundation

/// Common initializers for background services
public protocol BackgroundServiceInitializable: NSObjectProtocol {
    /// Initializes a new background service object
    ///
    /// - Parameter arguments: An array of command line arguments
    init(arguments: [String])
}
