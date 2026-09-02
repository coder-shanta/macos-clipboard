import Cocoa
import FlutterMacOS
import ServiceManagement

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let loginItemChannel = FlutterMethodChannel(
      name: "app.launch_at_login",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    loginItemChannel.setMethodCallHandler { call, result in
      guard #available(macOS 13.0, *) else {
        result(FlutterError(code: "UNSUPPORTED", message: "Requires macOS 13 or later", details: nil))
        return
      }
      switch call.method {
      case "isEnabled":
        result(SMAppService.mainApp.status == .enabled)
      case "enable":
        do {
          try SMAppService.mainApp.register()
          result(true)
        } catch {
          result(FlutterError(code: "ENABLE_FAILED", message: error.localizedDescription, details: nil))
        }
      case "disable":
        do {
          try SMAppService.mainApp.unregister()
          result(true)
        } catch {
          result(FlutterError(code: "DISABLE_FAILED", message: error.localizedDescription, details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}
