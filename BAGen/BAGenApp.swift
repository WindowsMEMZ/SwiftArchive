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

@main
struct BAGenApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State var debugConsoleContent = ""
    @State var nowMainScene = NowScene.Intro
    var body: some Scene {
        WindowGroup {
            Group {
                switch nowMainScene {
                case .Intro:
                    ContentView()
                        .onAppear {
                            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                                nowMainScene = nowScene
                            }
                        }
                case .TypeChoose:
                    TypeChooseView()
                case .FSEditChooser:
                    FSEditChooserView()
                case .FSEditor:
                    EmptyView()
                case .MTEditChooser:
                    EmptyView()
                case .MTEditor:
                    EmptyView()
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
}

func ChangeScene(to sceneName: NowScene) {
    nowScene = sceneName
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationDidFinishLaunching(_ application: UIApplication) {
        UIApplication.shared.isIdleTimerDisabled = true
//        signal(SIGABRT, { c in
//
//        })
    }
}
