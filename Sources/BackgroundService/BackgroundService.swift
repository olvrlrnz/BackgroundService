import Foundation

/// A GUI-less implementation of `NSApplication`
///
/// You can use a `BackgroundService` if you have an app bundle that uses the bundle format
/// but does not have any graphical user interface.
///
/// Even though it would be possible to just remove unnecessary components, the system might
/// still set up facilities that do not work in all situations, like linking to the AppKit framework,
/// which is not daemon safe, as outlined in
/// [Technical Note 2083](https://developer.apple.com/library/archive/technotes/tn2083/_index.html).
///
/// In those cases it might be beneficial to replace the usual application lifecycle with a `BackgroundService`.
///
/// How to use:
/// ===========
///
/// - Create a new target of type macOS Application
///
/// - Remove AppDelegate.swift and MainMenu.xib
///
/// - Create a class that implements the `BackgroundServicable` protocol
///
///         class MyBackgroundService: BackgroundServicable {
///             init(arguments: [String]) {
///                 self.arguments = arguments
///             }
///         }
///
/// - Add the class to the bundle's Info.plist and declare it UI-less
///
///         <key>NSPrincipalClass</key>
///         <string>$(MODULE_NAME).MyBackgroundService</string>
///         <key>LSUIElement</key>
///         <true/>
///
/// - Remove the NSMainNibFile key from the Info.plist
///
/// - Implement methods from `BackgroundServiceDelegate` you need
///
///         extension MyBackgroundService: BackgroundServiceDelegate {
///             func backgroundServiceDidFinishLaunching() {
///                 print("background service finished launching")
///             }
///
///             func backgroundServiceWillTerminate() {
///                 print("background service will terminate")
///             }
///
///             func backgroundServiceDidReceiveSignal(_ signal: Int32)
///                 print("background service received signal \(signal)")
///             }
///         }
@main
public class BackgroundService {
    /// The default instance
    static let `default` = BackgroundService()
    /// An instance of the class to run in the background
    private var instance: NSObjectProtocol?
    /// A list of active signal sources
    private var signalSources = [DispatchSourceSignal]()
    /// Condition for the loop in `BackgroundService.run(type:arguments:)`.
    /// When set to false, either through a `SIGTERM` or `BackgroundService.terminate()`,
    /// control will be handed back to the caller.
    private var shouldTerminate = false

    private init() {}

    /// Main function automatically called by the system after application startup
    private static func main() {
        guard let clazzName = Bundle.main.infoDictionary?["NSPrincipalClass"] as? String else {
            preconditionFailure("Info.plist does not contain a valid \"NSPrincipalClass\" entry")
        }

        guard let clazz = NSClassFromString(clazzName) else {
            preconditionFailure("\"\(clazzName)\" does not conform to \"BackgroundServicable\"")
        }

        self.default.run(type: clazz, arguments: CommandLine.arguments)
    }

    /// Stops executing the background service
    public static func terminate() {
        self.default.shouldTerminate = true
    }

    /// Runs a service
    ///
    /// - Parameters:
    ///   - type: The type of the object to run
    ///   - arguments: An array of command line arguments
    private func run(type: AnyClass, arguments: [String]) {
        self.setupSignalHandlers()

        let selector = NSSelectorFromString("init")

        if let type = type as? BackgroundServiceInitializable.Type {
            self.instance = type.init(arguments: arguments)
        } else if type.responds(to: selector) {
            self.instance = type.alloc() as? NSObjectProtocol
            self.instance?.perform(selector)
        } else {
            abort()
        }

        if let instance = self.instance as? BackgroundServiceDelegate {
            instance.backgroundServiceDidFinishLaunching()
        }

        repeat {
            if !RunLoop.current.run(mode: .default, before: .distantFuture) {
                print("RunLoop.run failed")
                self.shouldTerminate = true
            }
        } while !self.shouldTerminate

        self.signalSources.forEach {
            $0.cancel()
        }

        if let instance = self.instance as? BackgroundServiceDelegate {
            instance.backgroundServiceWillTerminate()
        }

        self.instance = nil

        Darwin.exit(EXIT_SUCCESS)
    }

    /// Sets up signal sources and attaches them to the current runloop
    private func setupSignalHandlers() {
        self.setupSignalHandler(
            forSignal: SIGTERM,
            handler: { self.shouldTerminate = true }
        )

        guard let instance = self.instance as? BackgroundServiceDelegate else {
            return
        }

        for signum in [SIGHUP, SIGINT, SIGCHLD, SIGUSR1, SIGUSR2] {
            self.setupSignalHandler(
                forSignal: signum,
                handler: { instance.backgroundServiceDidReceiveSignal(signum) }
            )
        }
    }

    /// Sets up a signal sources for a given signal number and attaches it to the current runloop
    ///
    /// - Parameters:
    ///   - signum: The signal number
    ///   - handler: An event handler called when the signal occurs
    private func setupSignalHandler(forSignal signum: Int32, handler: @escaping () -> ()) {
        let source = DispatchSource.makeSignalSource(signal: signum, queue: .main)

        source.setEventHandler(handler: handler)
        source.resume()

        signal(signum, SIG_IGN)
        self.signalSources.append(source)
    }
}
