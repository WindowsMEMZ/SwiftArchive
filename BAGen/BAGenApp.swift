//
//  BAGenApp.swift
//  BAGen
//
//  Created by WindowsMEMZ on 2023/10/1.
//

import Darwin
import SwiftUI
import AVFoundation
import UserNotifications

var mtEnterProjName = ""
var mtIsHaveUnsavedChange = false
var globalAudioPlayer = AVAudioPlayer()

@main
struct BAGenApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) var scenePhase
    @State var debugConsoleContent = ""
    var body: some Scene {
        WindowGroup {
            MTEditChooserView()
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .active:
                UIApplication.shared.isIdleTimerDisabled = true
                
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        // 用户已经同意授权
                    } else {
                        // 用户拒绝了授权
                    }
                }
            case .inactive:
                print("Inactive")
            case .background:
                // applicationDidEnterBackground
                if mtIsHaveUnsavedChange {
                    debugPrint("Unsaved Change")
                    let content = UNMutableNotificationContent()
                    content.title = "未保存的项目"
                    content.body = "您刚才编辑的项目尚未保存"
                    content.sound = UNNotificationSound.default
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
                    let request = UNNotificationRequest(identifier: "MTUnsavedChangeTip", content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("发送通知失败：\(error.localizedDescription)")
                        } else {
                            print("通知已发送")
                        }
                    }
                }
            @unknown default:
                break
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.hexEncodedString()
        debugPrint(tokenString)
        UserDefaults.standard.set(tokenString, forKey: "UserNotificationToken")
    }
}
