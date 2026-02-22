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
  
  // Pending screen index — set by Dart via bridge before window creation
  private static var pendingScreenIndex: Int = 0
  
  // Observer for sub-window close notification (X button)
  private static var closeObserver: NSObjectProtocol?
  
  // Ready-handshake: buffer messages until sub-window Dart handler is registered
  private static var subWindowReady: Bool = false
  private static var pendingPageMessages: [(method: String, arguments: Any?, result: FlutterResult)] = []

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
      
      // Store screenIndex before window creation
      if call.method == "setScreenIndex" {
        if let idx = (call.arguments as? NSNumber)?.intValue {
          MainFlutterWindow.pendingScreenIndex = idx
          print("[Bridge] pendingScreenIndex set to \(idx)")
        } else {
          print("[Bridge] WARNING: setScreenIndex received non-numeric argument: \(String(describing: call.arguments))")
        }
        result(nil)
        return
      }
      
      // Handle close directly from native — no round-trip through sub-window Dart
      if call.method == "close_window_with_exit" {
        if let window = MainFlutterWindow.subWindow {
          print("[Bridge] Closing sub-window directly from native")
          window.close()
          MainFlutterWindow.subWindowPageChannel = nil
          MainFlutterWindow.subWindow = nil
          MainFlutterWindow.subWindowReady = false
          MainFlutterWindow.pendingPageMessages.removeAll()
          result(nil)
        } else {
          result(FlutterError(code: "NO_WINDOW", message: "No presentation window available", details: nil))
        }
        return
      }
      
      // Forward all other methods to sub-window's page_data channel
      if let subChannel = MainFlutterWindow.subWindowPageChannel {
        if MainFlutterWindow.subWindowReady {
          print("[Bridge] Forwarding \(call.method) to sub-window page_data channel")
          subChannel.invokeMethod(call.method, arguments: call.arguments, result: result)
        } else {
          // Sub-window Dart handler not ready yet — buffer the message
          print("[Bridge] Sub-window not ready, buffering \(call.method) (\(MainFlutterWindow.pendingPageMessages.count + 1) pending)")
          MainFlutterWindow.pendingPageMessages.append((method: call.method, arguments: call.arguments, result: result))
        }
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
      
      // Reset ready state — new sub-window Dart engine needs to signal readiness
      MainFlutterWindow.subWindowReady = false
      MainFlutterWindow.pendingPageMessages.removeAll()
      
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
        
        // Remove previous close observer if any
        if let prev = MainFlutterWindow.closeObserver {
          NotificationCenter.default.removeObserver(prev)
        }
        // Observe willCloseNotification to detect X button close
        MainFlutterWindow.closeObserver = NotificationCenter.default.addObserver(
          forName: NSWindow.willCloseNotification,
          object: window,
          queue: .main
        ) { _ in
          print("[Bridge] Sub-window willCloseNotification fired (X button or native close)")
          // Clean up references
          MainFlutterWindow.subWindowPageChannel = nil
          MainFlutterWindow.subWindow = nil
          MainFlutterWindow.subWindowReady = false
          MainFlutterWindow.pendingPageMessages.removeAll()
          // Notify main window Dart that the presentation was closed
          if let mainNav = MainFlutterWindow.mainNavigationChannel {
            mainNav.invokeMethod("navigate", arguments: "window_closed")
          }
        }
        
        let windowChannel = FlutterMethodChannel(name: "com.songviewer/window",
                                                 binaryMessenger: controller.engine.binaryMessenger)
        MainFlutterWindow.subWindowControlChannel = windowChannel
        
        windowChannel.setMethodCallHandler { (call, result) in
          if call.method == "closeWindowWithExit" {
            // Presentation mode: just close the window (no fullscreen animation needed)
            window.close()
            MainFlutterWindow.subWindowPageChannel = nil
            MainFlutterWindow.subWindow = nil
            MainFlutterWindow.subWindowReady = false
            MainFlutterWindow.pendingPageMessages.removeAll()
            result(nil)
          } else if call.method == "closeWindow" {
            window.close()
            MainFlutterWindow.subWindowPageChannel = nil
            MainFlutterWindow.subWindow = nil
            MainFlutterWindow.subWindowReady = false
            MainFlutterWindow.pendingPageMessages.removeAll()
            result(nil)
          } else if call.method == "enterFullscreen" {
            // Already in presentation fullscreen — no-op
            result(nil)
          } else if call.method == "exitFullscreen" {
            // Already in presentation fullscreen — no-op
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
          // Intercept ready signal from sub-window Dart
          if call.method == "sub_window_ready" {
            MainFlutterWindow.subWindowReady = true
            print("[Bridge] Sub-window Dart handler is ready, flushing \(MainFlutterWindow.pendingPageMessages.count) buffered messages")
            // Flush all buffered messages to the now-ready sub-window
            if let subChannel = MainFlutterWindow.subWindowPageChannel {
              for pending in MainFlutterWindow.pendingPageMessages {
                print("[Bridge] Flushing buffered \(pending.method)")
                subChannel.invokeMethod(pending.method, arguments: pending.arguments, result: pending.result)
              }
            }
            MainFlutterWindow.pendingPageMessages.removeAll()
            result(nil)
            return
          }
          
          if let mainChannel = MainFlutterWindow.mainNavigationChannel {
            mainChannel.invokeMethod(call.method, arguments: call.arguments, result: result)
          } else {
            result(FlutterError(code: "NO_MAIN", message: "Main window navigation channel not available", details: nil))
          }
        }
        
        print("[Bridge] All channels registered on sub-window engine")
      }
      
      // Move new window to the correct screen based on screenIndex from Dart settings
      if let window = controller.view.window {
        let screens = NSScreen.screens
        print("[Bridge] Available screens: \(screens.count)")
        for (i, scr) in screens.enumerated() {
          print("[Bridge]   Screen \(i): \(scr.localizedName), frame=\(scr.frame), visibleFrame=\(scr.visibleFrame)")
        }
        
        // Use screenIndex that was set via bridge before window creation
        let targetScreenIndex = MainFlutterWindow.pendingScreenIndex
        print("[Bridge] screenIndex from pendingScreenIndex: \(targetScreenIndex)")
        
        // Clamp to valid range
        let screenIdx = min(max(targetScreenIndex, 0), screens.count - 1)
        let targetScreen = screens[screenIdx]
        // Use full screen frame (not visibleFrame) for true fullscreen
        let screenFrame = targetScreen.frame
        
        print("[Bridge] Target screen \(screenIdx): \(targetScreen.localizedName), frame: \(screenFrame)")
        
        // "Presentation fullscreen": borderless window filling the target screen
        // This is more reliable than toggleFullScreen which can snap to wrong screen
        window.styleMask = [.borderless]
        window.setFrame(screenFrame, display: true, animate: false)
        window.level = .statusBar  // Float above normal windows and menu bar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isOpaque = true
        window.backgroundColor = .black
        window.hasShadow = false
        
        window.makeKeyAndOrderFront(nil)
        
        print("[Bridge] Window placed in presentation fullscreen on screen \(screenIdx), frame: \(window.frame)")
      }
    }

    super.awakeFromNib()
  }
}
