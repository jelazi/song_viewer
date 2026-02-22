import Cocoa
import FlutterMacOS
import desktop_multi_window

class MainFlutterWindow: NSWindow {
  // Strong references to ALL channels — prevents ARC from deallocating handlers
  private static var presentationBridgeChannel: FlutterMethodChannel?
  private static var mainNavigationChannel: FlutterMethodChannel?
  private static var subWindowPageChannel: FlutterMethodChannel?
  private static var subWindowNavigateBridge: FlutterMethodChannel?
  private static var subWindowControlChannel: FlutterMethodChannel?
  
  // Store main engine's binary messenger so we can re-register channels later
  private static var mainBinaryMessenger: FlutterBinaryMessenger?
  
  // Reference to the sub-window so we can close it directly from the bridge
  private static weak var subWindow: NSWindow?

  /// Register (or re-register) the presentation_bridge handler on the main engine.
  /// Called both at startup AND every time a new sub-window is created,
  /// because desktop_multi_window may clear the handler table when spawning a new engine.
  private static func registerBridgeHandler() {
    guard let messenger = mainBinaryMessenger else {
      print("[Bridge] ERROR: mainBinaryMessenger is nil, cannot register bridge handler")
      return
    }
    
    let presentationBridge = FlutterMethodChannel(
      name: "com.songviewer/presentation_bridge",
      binaryMessenger: messenger
    )
    presentationBridgeChannel = presentationBridge
    
    presentationBridge.setMethodCallHandler { (call, result) in
      print("[Bridge] presentation_bridge received: \(call.method)")
      
      // Handle close directly from native — no round-trip through sub-window Dart
      if call.method == "close_window_with_exit" {
        if let window = MainFlutterWindow.subWindow {
          print("[Bridge] Closing sub-window directly from native")
          if window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
              window.close()
            }
          } else {
            window.close()
          }
          MainFlutterWindow.subWindowPageChannel = nil
          MainFlutterWindow.subWindow = nil
          result(nil)
        } else {
          result(FlutterError(code: "NO_WINDOW", message: "No presentation window available", details: nil))
        }
        return
      }
      
      // Forward all other methods to sub-window's page_data channel
      if let subChannel = MainFlutterWindow.subWindowPageChannel {
        print("[Bridge] Forwarding \(call.method) to sub-window page_data channel")
        subChannel.invokeMethod(call.method, arguments: call.arguments, result: result)
      } else {
        print("[Bridge] ERROR: subWindowPageChannel is nil, cannot forward \(call.method)")
        result(FlutterError(code: "NO_WINDOW", message: "No presentation window available", details: nil))
      }
    }
    
    print("[Bridge] presentation_bridge handler registered on main engine")
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Store main binary messenger for later re-registration
    MainFlutterWindow.mainBinaryMessenger = flutterViewController.engine.binaryMessenger
    
    // Initial registration of the bridge handler
    MainFlutterWindow.registerBridgeHandler()

    // Navigation channel on main window: receives forwarded navigation commands from sub-window
    let navigationChannel = FlutterMethodChannel(
      name: "com.songviewer/navigation",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    MainFlutterWindow.mainNavigationChannel = navigationChannel

    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      // Register the plugin which you want access from other isolate.
      RegisterGeneratedPlugins(registry: controller)
      
      print("[Bridge] Sub-window created, setting up channels on new engine")
      
      // RE-REGISTER the bridge handler on main engine.
      // desktop_multi_window may clear native handler tables when spawning a new engine.
      MainFlutterWindow.registerBridgeHandler()
      
      // Also re-register navigation channel handler (defensive)
      let navChannel = FlutterMethodChannel(
        name: "com.songviewer/navigation",
        binaryMessenger: MainFlutterWindow.mainBinaryMessenger!
      )
      MainFlutterWindow.mainNavigationChannel = navChannel
      
      // Register method channel for window control
      if let window = controller.view.window {
        // Keep a strong reference to the sub-window
        MainFlutterWindow.subWindow = window
        
        let windowChannel = FlutterMethodChannel(name: "com.songviewer/window",
                                                 binaryMessenger: controller.engine.binaryMessenger)
        MainFlutterWindow.subWindowControlChannel = windowChannel
        
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
            MainFlutterWindow.subWindowPageChannel = nil
            MainFlutterWindow.subWindow = nil
            result(nil)
          } else if call.method == "closeWindow" {
            window.close()
            MainFlutterWindow.subWindowPageChannel = nil
            MainFlutterWindow.subWindow = nil
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

        // Page data channel on sub-window: receives page updates from main window via bridge
        let pageDataChannel = FlutterMethodChannel(
          name: "com.songviewer/page_data",
          binaryMessenger: controller.engine.binaryMessenger
        )
        MainFlutterWindow.subWindowPageChannel = pageDataChannel

        // Navigate bridge on sub-window: sub-window Dart → native → main window Dart
        let navigateBridge = FlutterMethodChannel(
          name: "com.songviewer/navigate_bridge",
          binaryMessenger: controller.engine.binaryMessenger
        )
        MainFlutterWindow.subWindowNavigateBridge = navigateBridge
        
        navigateBridge.setMethodCallHandler { (call, result) in
          if let mainChannel = MainFlutterWindow.mainNavigationChannel {
            mainChannel.invokeMethod(call.method, arguments: call.arguments, result: result)
          } else {
            result(FlutterError(code: "NO_MAIN", message: "Main window navigation channel not available", details: nil))
          }
        }
        
        print("[Bridge] All channels registered on sub-window engine")
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
