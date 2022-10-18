import Foundation

/// Base protocol for background services
///
/// `BackgroundServicable` is composed of two separate protocols:
///   - `BackgroundServiceInitializable` governs how objects that should run in the background are initialized
///   - `BackgroundServiceDelegate` informs the background service about life cycle events
public protocol BackgroundServicable: BackgroundServiceInitializable, BackgroundServiceDelegate {}
