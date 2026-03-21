import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "rutio/notification_permission",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "getNotificationPermissionStatus" else {
          result(FlutterMethodNotImplemented)
          return
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
          let status: String
          switch settings.authorizationStatus {
          case .notDetermined:
            status = "notDetermined"
          case .denied:
            status = "denied"
          case .authorized:
            status = "authorized"
          case .provisional:
            status = "provisional"
          case .ephemeral:
            status = "authorized"
          @unknown default:
            status = "unknown"
          }

          DispatchQueue.main.async {
            result(status)
          }
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
