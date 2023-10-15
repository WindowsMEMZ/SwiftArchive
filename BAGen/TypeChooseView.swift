//
//  TypeChooseView.swift
//  BAGen
//
//  Created by WindowsMEMZ on 2023/10/2.
//

import SwiftUI
import DarockKit

struct TypeChooseView: View {
    @AppStorage("ResVersion") var resVersion = 0
    var body: some View {
        ZStack {
            Image("GlobalBGImage")
                .resizable()
                .ignoresSafeArea()
            VStack {
                BATopBar(navigationTitle: "选择编辑器")
                HStack {
                    Group {
                        AButton(action: {
//                            if resVersion != 0 {
//                                nowScene = .FSEditChooser
//                            } else {
//                                DarockKit.UIAlert.shared.presentAlert(title: "无法使用剧情编辑器", subtitle: "未下载附加资源", icon: .error, style: .iOS17AppleMusic, haptic: .error)
//                            }
                            DarockKit.UIAlert.shared.presentAlert(title: "无法使用剧情编辑器", subtitle: "剧情编辑器当前不可用", icon: .error, style: .iOS17AppleMusic, haptic: .error)
                        }, label: {
                            BAText("剧情编辑器", fontSize: 30, isSystemd: true)
                        })
                        AButton(action: {
                            nowScene = .MTEditChooser
                        }, label: {
                            BAText("Momotalk\n编辑器", fontSize: 30, isSystemd: true)
                        })
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    @ViewBuilder func AButton(action: @escaping () -> Void, label: () -> some View) -> some View {
        Button(action: {
            action()
        }, label: {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: 0xEEF5F9))
                    .frame(width: 200, height: 300)
                    .shadow(color: .black.opacity(0.8), radius: 5, x: 1, y: 2)
                label()
            }
            .frame(width: 200, height: 280)
        })
    }
}

#Preview {
    TypeChooseView()
}
