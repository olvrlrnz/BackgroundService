import Foundation

/// Life-Cycle events for background services
public protocol BackgroundServiceDelegate {
    /// Informs the delegate that the background service has finished launching.
    func backgroundServiceDidFinishLaunching()

    /// Informs the delegate that the background service is about to terminate
    func backgroundServiceWillTerminate()

    /// Informs the delegate that the background service has received a signal from the operating system
    ///
    /// - Parameter signal: The signal number that was received
    func backgroundServiceDidReceiveSignal(_ signal: Int32)
}

public extension BackgroundServiceDelegate {
    /// Default implementation that does nothing
    func backgroundServiceDidFinishLaunching() {}

    /// Default implementation that does nothing
    func backgroundServiceWillTerminate() {}

    /// Default implementation that does nothing
    func backgroundServiceDidReceiveSignal(_: Int32) {}
}
