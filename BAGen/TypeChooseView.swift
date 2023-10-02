//
//  TypeChooseView.swift
//  BAGen
//
//  Created by WindowsMEMZ on 2023/10/2.
//

import SwiftUI

struct TypeChooseView: View {
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
                            nowScene = .FSEditChooser
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
