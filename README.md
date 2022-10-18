# BackgroundService

A GUI-less implementation of `NSApplication`

You can use a `BackgroundService` if you have an app bundle that uses the bundle format
but does not have any graphical user interface.

Even though it would be possible to just remove unnecessary components, the system might
still set up facilities that do not work in all situations, like linking to the `AppKit` framework,
which is not daemon safe, as outlined in
[Technical Note 2083](https://developer.apple.com/library/archive/technotes/tn2083/_index.html).

In those cases it might be beneficial to replace the usual application lifecycle with a `BackgroundService`.


## How to use:

- Create a new target of type macOS Application

- Remove `AppDelegate.swift` and `MainMenu.xib`

- Create a class that implements the `BackgroundServicable` protocol
    ```swift
        class MyBackgroundService: BackgroundServicable {
            init(arguments: [String]) {
                self.arguments = arguments
            }
        }
    ```

- Add the class to the bundle's Info.plist and declare it UI-less
    ```plist
        <key>NSPrincipalClass</key>
        <string>$(MODULE_NAME).MyBackgroundService</string>
        <key>LSUIElement</key>
        <true/>
    ```

- Remove the `NSMainNibFile` key from the Info.plist

- Implement methods from `BackgroundServiceDelegate` you need
    ```swift
        extension MyBackgroundService: BackgroundServiceDelegate {
            func backgroundServiceDidFinishLaunching() {
                print("background service finished launching")
            }

            func backgroundServiceWillTerminate() {
                print("background service will terminate")
            }

            func backgroundServiceDidReceiveSignal(_ signal: Int32)
                print("background service received signal \(signal)")
            }
        }
    ```