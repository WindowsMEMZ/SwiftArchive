//
//  BAGenApp.swift
//  BAGen
//
//  Created by WindowsMEMZ on 2023/10/1.
//

import Darwin
import SwiftUI

@main
struct BAGenApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationDidFinishLaunching(_ application: UIApplication) {
//        signal(SIGABRT, { c in
//
//        })
    }
}
