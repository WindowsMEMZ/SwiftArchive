//
//  SettingsView.swift
//  BAGen
//
//  Created by memz233 on 2023/10/15.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("IsAllowIntoDevelopingArea") var isAllowIntoDevelopingArea = false
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("高级")) {
                    Toggle("开发区域访问", isOn: $isAllowIntoDevelopingArea)
                }
            }
            .navigationTitle("设置")
        }
    }
}

#Preview {
    SettingsView()
}
