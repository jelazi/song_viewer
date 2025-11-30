import Cocoa
import FlutterMacOS
import desktop_multi_window

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      // Register the plugin which you want access from other isolate.
      RegisterGeneratedPlugins(registry: controller)
      
      // Register method channel for window control
      if let window = controller.view.window {
        let windowChannel = FlutterMethodChannel(name: "com.songviewer/window",
                                                 binaryMessenger: controller.engine.binaryMessenger)
        windowChannel.setMethodCallHandler { (call, result) in
          if call.method == "closeWindowWithExit" {
            // Exit fullscreen if needed, then close
            if window.styleMask.contains(.fullScreen) {
              window.toggleFullScreen(nil)
              // Wait for fullscreen animation, then close
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                window.close()
              }
            } else {
              // Not in fullscreen, close immediately
              window.close()
            }
            result(nil)
          } else if call.method == "closeWindow" {
            window.close()
            result(nil)
          } else if call.method == "enterFullscreen" {
            if !window.styleMask.contains(.fullScreen) {
              window.toggleFullScreen(nil)
            }
            result(nil)
          } else if call.method == "exitFullscreen" {
            if window.styleMask.contains(.fullScreen) {
              window.toggleFullScreen(nil)
            }
            result(nil)
          } else {
            result(FlutterMethodNotImplemented)
          }
        }
      }
      
      // Move new window to secondary screen if available and enter fullscreen
      if let window = controller.view.window {
        let screens = NSScreen.screens
        print("Available screens: \(screens.count)")
        
        if screens.count > 1 {
          // Find a screen that is NOT the main screen
          if let secondaryScreen = screens.first(where: { $0 != NSScreen.main }) {
            // Get the visible frame of the secondary screen
            let screenFrame = secondaryScreen.visibleFrame
            
            // Create a window frame on the secondary screen
            let windowWidth: CGFloat = screenFrame.width
            let windowHeight: CGFloat = screenFrame.height
            let windowX = screenFrame.origin.x
            let windowY = screenFrame.origin.y
            
            let newFrame = NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight)
            
            // Set the window frame
            window.setFrame(newFrame, display: true)
            print("Window frame set to: \(newFrame)")
            
            // Make window visible first
            window.makeKeyAndOrderFront(nil)
            
            // Enter fullscreen mode with longer delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
              print("Attempting to enter fullscreen...")
              window.toggleFullScreen(nil)
              print("Fullscreen toggled")
            }
            
            print("Window moved to secondary screen: \(secondaryScreen.localizedName)")
          }
        } else {
          // Only one screen - enter fullscreen on main screen
          window.makeKeyAndOrderFront(nil)
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("Attempting to enter fullscreen on main screen...")
            window.toggleFullScreen(nil)
          }
          print("Only one screen available, entering fullscreen on main screen")
        }
      }
    }

    super.awakeFromNib()
  }
}

