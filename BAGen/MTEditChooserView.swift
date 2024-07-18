//
//  MTEditChooserView.swift
//  BAGen
//
//  Created by memz233 on 2023/10/5.
//

import SwiftUI
import DarockKit
import UniformTypeIdentifiers

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
            .refreshable {
                RefreshProjects()
            }
            .fileImporter(isPresented: $isImportDocPickerPresented, allowedContentTypes: [.sapm]) { result in
                switch result {
                case .success(let url):
                    _ = url.startAccessingSecurityScopedResource()
                    do {
                        try String(contentsOf: url, encoding: .utf8).write(toFile: NSHomeDirectory() + "/Documents/MTProj/\(url.lastPathComponent)", atomically: true, encoding: .utf8)
                        RefreshProjects()
                    } catch {
                        print(error)
                    }
                    url.stopAccessingSecurityScopedResource()
                case .failure(let error):
                    AlertKitAPI.present(title: "导入项目时出错", subtitle: error.localizedDescription, icon: .error, style: .iOS17AppleMusic, haptic: .error)
                }
            }
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
                        isImportDocPickerPresented = true
                    }, label: {
                        Image(systemName: "square.and.arrow.down")
                    })
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isNewProjPresented = true
                    }, label: {
                        Image(systemName: "plus")
                    })
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
