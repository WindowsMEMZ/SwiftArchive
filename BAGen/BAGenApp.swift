//
//  BAGenApp.swift
//  BAGen
//
//  Created by WindowsMEMZ on 2023/10/1.
//

import Darwin
import SwiftUI
import UserNotifications

var debugConsoleText = ""
var nowScene = NowScene.Intro
var fsEnterProjName = ""
var mtEnterProjName = ""
var mtIsHaveUnsavedChange = false
var isGlobalAlertPresented = false
var globalAlertContent: (() -> AnyView)?

@main
struct BAGenApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) var scenePhase
    @State var debugConsoleContent = ""
    @State var nowMainScene = NowScene.Intro
    var body: some Scene {
        WindowGroup {
            MTEditChooserView()
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .active:
                // applicationDidFinishLaunching
                if UserDefaults.standard.string(forKey: "CrashData") != nil {
                    nowScene = .CrashReporter
                }
                
                UIApplication.shared.isIdleTimerDisabled = true
                signal(SIGABRT, { c in
                    CrashHander(signalStr: "SIGABRT", signalCode: c)
                })
                signal(SIGTRAP, { c in
                    CrashHander(signalStr: "SIGTRAP", signalCode: c)
                })
                signal(SIGILL, { c in
                    CrashHander(signalStr: "SIGILL", signalCode: c)
                })
                
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

enum NowScene {
    case Intro
    case TypeChoose
    case FSEditChooser
    case FSEditor
    case MTEditChooser
    case MTEditor
    case EachCharacters
    case CrashReporter
}

func ChangeScene(to sceneName: NowScene) {
    nowScene = sceneName
}

class AppDelegate: NSObject, UIApplicationDelegate {
    
}

func CrashHander(signalStr: String, signalCode: Int32) {
    let fullTrack = """
    -------------------------------------
    Translated Report (Full Report Below)
    -------------------------------------
    
    Incident Identifier: \(UUID().uuidString)
    Hardware Model:      \(UIDevice.current.model)
    Process:             \(ProcessInfo.processInfo.processName) [\(ProcessInfo.processInfo.processIdentifier)]
    Version:             \(Bundle.main.infoDictionary!["CFBundleShortVersionString"]! as! String)
    
    Date/Time:           \({ () -> String in
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
        return df.string(from: Date())
    }())
    OS Version:          \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
    Report Version:      1
    
    Exception Type:  (\(signalStr))
    Termination Reason: (\(signalStr) \(signalCode))
    
    \(Thread.callStackSymbols)
    """
    UserDefaults.standard.set(fullTrack, forKey: "CrashData")
    exit(1)
}
