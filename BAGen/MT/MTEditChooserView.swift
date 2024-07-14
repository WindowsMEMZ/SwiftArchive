//
//  MTEditChooserView.swift
//  BAGen
//
//  Created by memz233 on 2023/10/5.
//

import SwiftUI
import UniformTypeIdentifiers

//struct MTEditChooserView: View {
//    @AppStorage("MTIsFirstUsing") var isFirstUsing = true
//    @State var projNames = [String]()
//    @State var newProjNameCache = ""
//    @State var isImportDocPickerPresented = false
//    var body: some View {
//        ZStack {
//            Image("GlobalBGImage")
//                .resizable()
//                .ignoresSafeArea()
//            VStack {
//                BATopBar(backAction: {
//                    nowScene = .TypeChoose
//                }, navigationTitle: "选择聊天")
//                HStack {
//                    ZStack {
//                        RoundedRectangle(cornerRadius: 8)
//                            .fill(Color(hex: 0xF1FAFC))
//                            .frame(width: 280, height: 280)
//                    }
//                    Spacer()
//                        .frame(width: 25)
//                    ZStack {
//                        RoundedRectangle(cornerRadius: 8)
//                            .fill(.gray.opacity(0.3))
//                            .frame(width: 280, height: 280)
//                        VStack {
//                            Spacer()
//                                .frame(height: 15)
//                            ZStack {
//                                RoundedRectangle(cornerRadius: 8)
//                                    .fill(Color(hex: 0x274366))
//                                    .frame(width: 250, height: 24)
//                                BAText("聊天目录", fontSize: 17, textColor: .white, isSystemd: true)
//                                    .offset(x: -10)
//                                HStack {
//                                    Spacer()
//                                    Button(action: {
//                                        isImportDocPickerPresented = true
//                                    }, label: {
//                                        ZStack {
//                                            Circle()
//                                                .fill(Color(hex: 0x3D578D))
//                                                .frame(width: 35, height: 35)
//                                            Image(systemName: "square.and.arrow.down")
//                                                .font(.system(size: 20, weight: .bold))
//                                                .foregroundColor(.white)
//                                        }
//                                    })
//                                    .fileImporter(isPresented: $isImportDocPickerPresented, allowedContentTypes: [.sapm]) { result in
//                                        switch result {
//                                        case .success(let fUrl):
////                                            let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(fUrl.lastPathComponent)
////                                            if FileManager.default.fileExists(atPath: destinationURL.path) {
////                                                try! FileManager.default.removeItem(at: destinationURL)
////                                            }
////                                            try! FileManager.default.copyItem(at: fUrl, to: destinationURL)
////                                            try! FileManager.default.copyItem(at: destinationURL, to: AppFileManager(path: "MTProj").GetPath(String(fUrl.path.split(separator: "/").last!)).url)
//                                            _ = fUrl.startAccessingSecurityScopedResource()
//                                            do {
//                                                try FileManager.default.copyItem(at: fUrl, to: AppFileManager(path: "MTProj").GetPath(String(fUrl.path.split(separator: "/").last!)).url)
//                                            } catch {
//                                                debugPrint(error)
//                                            }
//                                            fUrl.stopAccessingSecurityScopedResource()
//                                            projNames.removeAll()
//                                            for pn in AppFileManager(path: "MTProj").GetRoot() ?? [[String: String]]() {
//                                                projNames.append(pn["name"]!)
//                                            }
//                                        case .failure(let error):
//                                            debugPrint(error)
//                                        }
//                                    }
//                                    Button(action: {
//                                        globalAlertContent = {
//                                            AnyView(
//                                                VStack {
//                                                    BAText("创建项目", fontSize: 24, isSystemd: true)
//                                                    Spacer()
//                                                        .frame(height: 20)
//                                                    TextField("项目名", text: $newProjNameCache)
//                                                        .padding(.horizontal, 10)
//                                                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
//                                                    Spacer()
//                                                        .frame(height: 20)
//                                                    HStack {
//                                                        BAButton(action: {
//                                                            isGlobalAlertPresented = false
//                                                            globalAlertContent = nil
//                                                        }, label: "取消")
//                                                        BAButton(action: {
//                                                            if !newProjNameCache.hasPrefix(".") {
//                                                                let fp = AppFileManager(path: "MTProj").GetPath("root")
//                                                                debugPrint(fp)
//                                                                try! """
//                                                                +
//                                                                -
//                                                                
//                                                                """.write(toFile: fp.path + "/\(newProjNameCache).sapm", atomically: true, encoding: .utf8)
//                                                                projNames.removeAll()
//                                                                for pn in AppFileManager(path: "MTProj").GetRoot() ?? [[String: String]]() {
//                                                                    projNames.append(pn["name"]!)
//                                                                }
//                                                                isGlobalAlertPresented = false
//                                                                globalAlertContent = nil
//                                                            } else {
//                                                                
//                                                            }
//                                                        }, label: "创建", isHighlighted: true)
//                                                    }
//                                                }
//                                            )
//                                        }
//                                        isGlobalAlertPresented = true
//                                    }, label: {
//                                        ZStack {
//                                            Circle()
//                                                .fill(Color(hex: 0xF3E33F))
//                                                .frame(width: 35, height: 35)
//                                            Image(systemName: "plus")
//                                                .font(.system(size: 20, weight: .bold))
//                                                .foregroundColor(.white)
//                                        }
//                                    })
//                                    Spacer()
//                                        .frame(width: 20)
//                                }
//                            }
//                            ScrollView {
//                                VStack {
//                                    if projNames.count != 0 {
//                                        ForEach(0..<projNames.count, id: \.self) { i in
//                                            if !projNames[i].hasPrefix(".") {
//                                                ZStack {
//                                                    RoundedRectangle(cornerRadius: 8)
//                                                        .fill(Color(hex: 0xEDF3F6))
//                                                        .frame(width: 255, height: 50)
//                                                        .shadow(color: .black, radius: 2, x: 2, y: 0)
//                                                    HStack {
//                                                        VStack {
//                                                            BAText(projNames[i], fontSize: 18, isSystemd: true)
//                                                                .padding(.horizontal, 8)
//                                                            Spacer()
//                                                        }
//                                                        Spacer()
//                                                        Button(action: {
//                                                            mtEnterProjName = projNames[i]
//                                                            nowScene = .MTEditor
//                                                        }, label: {
//                                                            ZStack {
//                                                                Image("SmallButtonImage")
//                                                                    .shadow(color: .black, radius: 2, x: 2, y: 0)
//                                                                BAText("进入", fontSize: 18, isSystemd: true)
//                                                            }
//                                                            .padding(.horizontal, 8)
//                                                        })
//                                                    }
//                                                    .padding(5)
//                                                }
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//                    .frame(width: 280, height: 280)
//                }
//            }
//        }
//        .onAppear {
//            if isFirstUsing {
//                AppFileManager(path: "").CreateFolder("MTProj")
//                isFirstUsing = false
//            }
//            debugPrint(AppFileManager(path: "").GetRoot() ?? "No Root Files")
//            for pn in AppFileManager(path: "MTProj").GetRoot() ?? [[String: String]]() {
//                projNames.append(pn["name"]!)
//            }
//            debugPrint(projNames)
//        }
//    }
//}

struct MTEditChooserView: View {
    @AppStorage("MTIsFirstUsing") var isFirstUsing = true
    @State var projNames = [String]()
    @State var isImportDocPickerPresented = false
    @State var isNewProjPresented = false
    @State var newProjNameInput = ""
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if projNames.count != 0 {
                        ForEach(0..<projNames.count, id: \.self) { i in
                            if !projNames[i].hasPrefix(".") {
                                NavigationLink(destination: { MTEditorView(projName: projNames[i]) }, label: {
                                    Text(projNames[i])
                                })
                            }
                        }
                    } else {
                        Text("无项目")
                    }
                }
            }
            .navigationTitle("SwiftArchive")
            .alert("新建项目", isPresented: $isNewProjPresented, actions: {
                TextField("项目名", text: $newProjNameInput)
                Button(role: .cancel, action: {
                    
                }, label: {
                    Text("取消")
                })
                Button(action: {
                    if !newProjNameInput.hasPrefix(".") {
                        let fp = AppFileManager(path: "MTProj").GetPath("root")
                        debugPrint(fp)
                        try! """
                        +
                        -
                        
                        """.write(toFile: fp.path + "/\(newProjNameInput).sapm", atomically: true, encoding: .utf8)
                        RefreshProjects()
                    }
                }, label: {
                    Text("创建")
                })
            }, message: {
                Text("项目信息")
            })
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isNewProjPresented = true
                    }, label: {
                        Image(systemName: "plus")
                    })
                }
            }
        }
        .onAppear {
            if isFirstUsing {
                AppFileManager(path: "").CreateFolder("MTProj")
                isFirstUsing = false
            }
            debugPrint(AppFileManager(path: "").GetRoot() ?? "No Root Files")
            RefreshProjects()
        }
    }
    
    func RefreshProjects() {
        projNames.removeAll()
        for pn in AppFileManager(path: "MTProj").GetRoot() ?? [[String: String]]() {
            projNames.append(pn["name"]!)
        }
        debugPrint(projNames)
    }
}
    

#Preview {
    MTEditChooserView()
}
