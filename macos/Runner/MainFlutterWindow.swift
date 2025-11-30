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
      
      // Move new window to secondary screen if available and enter fullscreen
      if let window = controller.view.window {
        let screens = NSScreen.screens
        if screens.count > 1 {
          // Find a screen that is NOT the main screen
          if let secondaryScreen = screens.first(where: { $0 != NSScreen.main }) {
            // Get the visible frame of the secondary screen
            let screenFrame = secondaryScreen.visibleFrame
            
            // Create a window frame on the secondary screen
            let windowWidth: CGFloat = screenFrame.width * 0.9
            let windowHeight: CGFloat = screenFrame.height * 0.9
            let windowX = screenFrame.origin.x + (screenFrame.width - windowWidth) / 2
            let windowY = screenFrame.origin.y + (screenFrame.height - windowHeight) / 2
            
            let newFrame = NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight)
            
            // Set the window frame
            window.setFrame(newFrame, display: true)
            
            // Enter fullscreen mode
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
              window.toggleFullScreen(nil)
            }
            
            print("Window moved to secondary screen and entering fullscreen: \(secondaryScreen.localizedName)")
          }
        } else {
          // Only one screen - enter fullscreen on main screen
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            window.toggleFullScreen(nil)
          }
          print("Only one screen available, entering fullscreen on main screen")
        }
      }
    }

    super.awakeFromNib()
  }
}

