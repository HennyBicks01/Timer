import UIKit
import Flutter
import Intents

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var timerChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    timerChannel = FlutterMethodChannel(
      name: "com.example.timer_pip/timer",
      binaryMessenger: controller.binaryMessenger
    )
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(
    _ application: UIApplication,
    handle intent: INIntent,
    completionHandler: @escaping (INIntentResponse) -> Void
  ) {
    if let timerIntent = intent as? INSetTimerIntent {
      let seconds = Int(timerIntent.duration ?? 0)
      if seconds > 0 {
        timerChannel?.invokeMethod("setTimer", arguments: seconds)
        completionHandler(INSetTimerIntentResponse(code: .success, userActivity: nil))
      } else {
        completionHandler(INSetTimerIntentResponse(code: .failure, userActivity: nil))
      }
    }
  }
}
