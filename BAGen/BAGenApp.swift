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
    @State var isAlertPresented = false
    @State var alertContent: (() -> AnyView)? = nil
    var body: some Scene {
        WindowGroup {
            Group {
                switch nowMainScene {
                case .Intro:
                    ContentView()
                        .onAppear {
                            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                                nowMainScene = nowScene
                                isAlertPresented = isGlobalAlertPresented
                                alertContent = globalAlertContent
                            }
                        }
                case .TypeChoose:
                    TypeChooseView()
                case .FSEditChooser:
                    FSEditChooserView()
                case .FSEditor:
                    FSEditorView()
                case .MTEditChooser:
                    MTEditChooserView()
                case .MTEditor:
                    MTEditorView()
                case .EachCharacters:
                    EachCharactersView.Serika()
                case .CrashReporter:
                    CrashReporterView()
                }
            }
            .overlay {
                if isAlertPresented, let content = globalAlertContent {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: 0xECECEC))
                            .frame(width: 350, height: 260)
                        VStack {
                            HStack {
                                Image("PopupTopBarImage")
                                Spacer()
                                Button(action: {
                                    isGlobalAlertPresented = false
                                    globalAlertContent = nil
                                }, label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(hex: 0x283D59))
                                })
                                .padding(.horizontal, 5)
                            }
                            Spacer()
                            Image("PopupBackgroundImage")
                        }
                        VStack {
                            Spacer()
                                .frame(height: 40)
                            content()
                        }
                    }
                    .frame(width: 350, height: 260)
                }
            }
        }
        .onChange(of: scenePhase) { value in
            switch value {
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
    public static var orientationLock = UIInterfaceOrientationMask.landscape
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
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
