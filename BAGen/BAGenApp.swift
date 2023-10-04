//
//  BAGenApp.swift
//  BAGen
//
//  Created by WindowsMEMZ on 2023/10/1.
//

import Darwin
import SwiftUI

var debugConsoleText = ""
var nowScene = NowScene.Intro
var fsEnterProjName = ""
var isGlobalAlertPresented = false
var globalAlertContent: (() -> AnyView)?

@main
struct BAGenApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
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
                    EmptyView()
                case .MTEditor:
                    EmptyView()
                case .EachCharacters:
                    EachCharactersView.Serika()
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
//                .overlay(alignment: .topTrailing) {
//                    ZStack {
//                        RoundedRectangle(cornerRadius: 8).fill(.black).opacity(0.4)
//                            .frame(width: 200, height: 100)
//                        ScrollView {
//                            HStack {
//                                Text(debugConsoleContent)
//                                    .foregroundColor(.white)
//                                    .font(.system(size: 16))
//                                    .onAppear {
//                                        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
//                                            debugConsoleContent = debugConsoleText
//                                        }
//                                    }
//                                Spacer()
//                            }
//                        }
//                        .padding(5)
//                    }
//                    .frame(width: 200, height: 100)
//                    .allowsHitTesting(false)
//                }
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
}

func ChangeScene(to sceneName: NowScene) {
    nowScene = sceneName
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationDidFinishLaunching(_ application: UIApplication) {
        UIApplication.shared.isIdleTimerDisabled = true
        signal(SIGABRT, { c in
            CrashHander(signalStr: "SIGABRT", signalCode: c)
        })
    }
}

func CrashHander(signalStr: String, signalCode: Int32) {
    var fullTrack = """
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
    
    
    """
}
