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
    @State var newProjNameCache = ""
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
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        globalAlertContent = {
                                            AnyView(
                                                VStack {
                                                    BAText("创建项目", fontSize: 24, isSystemd: true)
                                                    Spacer()
                                                        .frame(height: 20)
                                                    TextField("项目名", text: $newProjNameCache)
                                                        .padding(.horizontal, 10)
                                                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
                                                    Spacer()
                                                        .frame(height: 20)
                                                    HStack {
                                                        BAButton(action: {
                                                            isGlobalAlertPresented = false
                                                            globalAlertContent = nil
                                                        }, label: "取消")
                                                        BAButton(action: {
                                                            if !newProjNameCache.hasPrefix(".") {
                                                                let fp = AppFileManager(path: "FSProj").GetPath("root")
                                                                debugPrint(fp)
                                                                try! """
                                                                +
                                                                -
                                                                
                                                                """.write(toFile: fp.path + "/\(newProjNameCache).sap", atomically: true, encoding: .utf8)
                                                                projNames.removeAll()
                                                                for pn in AppFileManager(path: "FSProj").GetRoot() ?? [[String: String]]() {
                                                                    projNames.append(pn["name"]!)
                                                                }
                                                                isGlobalAlertPresented = false
                                                                globalAlertContent = nil
                                                            } else {
                                                                
                                                            }
                                                        }, label: "创建", isHighlighted: true)
                                                    }
                                                }
                                            )
                                        }
                                        isGlobalAlertPresented = true
                                    }, label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: 0xF3E33F))
                                                .frame(width: 35, height: 35)
                                            Image(systemName: "plus")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    })
                                    Spacer()
                                        .frame(width: 20)
                                }
                            }
                            ScrollView {
                                VStack {
                                    if projNames.count != 0 {
                                        ForEach(0..<projNames.count, id: \.self) { i in
                                            if !projNames[i].hasPrefix(".") {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color(hex: 0xEDF3F6))
                                                        .frame(width: 255, height: 50)
                                                        .shadow(color: .black, radius: 2, x: 2, y: 0)
                                                    HStack {
                                                        VStack {
                                                            BAText(projNames[i], fontSize: 18, isSystemd: true)
                                                                .padding(.horizontal, 8)
                                                            Spacer()
                                                        }
                                                        Spacer()
                                                        Button(action: {
                                                            fsEnterProjName = projNames[i]
                                                            nowScene = .FSEditor
                                                        }, label: {
                                                            ZStack {
                                                                Image("SmallButtonImage")
                                                                    .shadow(color: .black, radius: 2, x: 2, y: 0)
                                                                BAText("进入", fontSize: 18, isSystemd: true)
                                                            }
                                                            .padding(.horizontal, 8)
                                                        })
                                                    }
                                                    .padding(5)
                                                }
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
            debugPrint(projNames)
        }
    }
}

#Preview {
    FSEditChooserView()
}
