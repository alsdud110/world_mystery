import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var seasonPacks: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SeasonPacks") {
      seasonPacks = FlutterMethodChannel(name: "world_mystery/season_packs", binaryMessenger: registrar.messenger())
      seasonPacks?.setMethodCallHandler(AppDelegate.seasonPacksCall)
    }
  }

  /// The season packs' folder (season_pack_downloads.dart): left out of
  /// iCloud backups (downloaded again whenever needed; the game's progress
  /// and profile are elsewhere and still backed up), and the space free on
  /// its volume, checked before a download.
  private static func seasonPacksCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // A debug build's project folder (Debug.xcconfig; empty in a release).
    if call.method == "projectDir" {
      result(Bundle.main.object(forInfoDictionaryKey: "WMProjectDir") as? String)
      return
    }
    guard let path = call.arguments as? String else {
      result(FlutterError(code: "arguments", message: "a folder path", details: nil))
      return
    }
    var folder = URL(fileURLWithPath: path, isDirectory: true)
    switch call.method {
    case "excludeFromBackup":
      do {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try folder.setResourceValues(values)
        result(nil)
      } catch {
        result(FlutterError(code: "excludeFromBackup", message: error.localizedDescription, details: nil))
      }
    case "freeBytes":
      let values = try? folder.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
      if let free = values?.volumeAvailableCapacityForImportantUsage {
        result(NSNumber(value: free))
      } else {
        result(nil)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
