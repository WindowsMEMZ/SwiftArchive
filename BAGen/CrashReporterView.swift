//
//  CrashReporterView.swift
//  BAGen
//
//  Created by memz233 on 2023/10/5.
//

import SwiftUI

struct CrashReporterView: View {
    var body: some View {
        ScrollView {
            VStack {
                Text("SwiftArchive 似乎在上次运行中出现了问题")
                    .font(.system(size: 22, weight: .bold))
                Text("以下是上次的错误信息:")
                    .font(.system(size: 20))
                ScrollView {
                    Text(UserDefaults.standard.string(forKey: "CrashData")!)
                }
                .frame(maxHeight: 200)
                Button(action: {
                    UserDefaults.standard.removeObject(forKey: "CrashData")
                    nowScene = .Intro
                }, label: {
                    Text("返回首页")
                })
            }
        }
    }
}

#Preview {
    CrashReporterView()
}
