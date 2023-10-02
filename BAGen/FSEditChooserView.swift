//
//  FSEditChooserView.swift
//  BAGen
//
//  Created by WindowsMEMZ on 2023/10/2.
//

import SwiftUI

struct FSEditChooserView: View {
    @AppStorage("FSIsFirstUsing") var isFirstUsing = true
    @State var projNames = [String]()
    var body: some View {
        ZStack {
            Image("GlobalBGImage")
                .resizable()
                .ignoresSafeArea()
            VStack {
                BATopBar(backAction: {
                    nowScene = .TypeChoose
                }, navigationTitle: "选择剧情")
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: 0xF1FAFC))
                            .frame(width: 280, height: 280)
                    }
                    Spacer()
                        .frame(width: 25)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray.opacity(0.3))
                            .frame(width: 280, height: 280)
                        VStack {
                            Spacer()
                                .frame(height: 15)
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: 0x274366))
                                    .frame(width: 250, height: 24)
                                BAText("剧情目录", fontSize: 17, textColor: .white, isSystemd: true)
                            }
                            ScrollView {
                                VStack {
                                    if projNames.count != 0 {
                                        ForEach(0..<projNames.count, id: \.self) { i in
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(hex: 0xEDF3F6))
                                                    .frame(width: 255, height: 34)
                                                    .shadow(color: .black, radius: 2, x: 2, y: 0)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: 280, height: 280)
                }
            }
        }
        .onAppear {
            if isFirstUsing {
                AppFileManager(path: "").CreateFolder("FSProj")
                isFirstUsing = false
            }
            debugPrint(AppFileManager(path: "").GetRoot() ?? "No Root Files")
            for pn in AppFileManager(path: "FSProj").GetRoot() ?? [[String: String]]() {
                projNames.append(pn["name"]!)
            }
        }
    }
}

#Preview {
    FSEditChooserView()
}
