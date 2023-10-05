//
//  MTEditorView.swift
//  BAGen
//
//  Created by memz233 on 2023/10/5.
//

import SwiftUI
import DarockKit
import SwiftyJSON

// 文件格式:
// 文本对话: {角色 ID(String)}|{头像组下标(Int)}|{内容}|{ShowldShowAsNew(Bool)}
// 图片:    {角色 ID(String)}|{头像组下标(Int)}|"%%TImage%%*"(图像标记){图像 Base64}|{ShowldShowAsNew(Bool)}
// 按行分隔
// 角色 ID 为 "Sensei" 时显示消息由我方发出

//!!!: On this view, UIScreen.main.bounds' height & width were exchanged
struct MTEditorView: View {
    var projName: String = mtEnterProjName
    @State var fullProjData: MTBase.FullData?
    @State var newMessageTextCache = ""
    @State var isChatActionsPresented = false
    @State var currentSelectCharacterData = MTBase.SingleCharacterData(id: "Sensei", fullName: "", shortName: "", imageNames: [""])
    @State var currentSelectCharacterImageGroupIndex = 0
    @State var characterSelectTab: [[String: Any]]? = nil
    @State var isTippedBads = false
    @State var isInserting = false
    var body: some View {
        ZStack {
            Color(hex: 0xFFF6DD)
                .ignoresSafeArea()
            VStack {
                if isInserting {
                    BAText("插入模式\n轻触一条消息以插入新消息到下方", fontSize: 18, isSystemd: true)
                        .multilineTextAlignment(.center)
                }
                ScrollView {
                    if fullProjData != nil {
                        ForEach(0..<fullProjData!.chatData.count, id: \.self) { i in
                            if fullProjData!.chatData[i].characterId != "Sensei" {
                                HStack {
                                    let thisCharacterData = MTBase().getCharacterData(byId: fullProjData!.chatData[i].characterId)!
                                    if fullProjData!.chatData[i].showldShowAsNew {
                                        Image(uiImage: UIImage(data: try! Data(contentsOf: Bundle.main.url(forResource: thisCharacterData.imageNames[fullProjData!.chatData[i].imageGroupIndex], withExtension: "png")!))!)
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.clear)
                                            .frame(width: 50, height: 50)
                                    }
                                    VStack {
                                        if fullProjData!.chatData[i].showldShowAsNew {
                                            BAText(thisCharacterData.shortName, fontSize: 18, isSystemd: true)
                                                .padding(0)
                                                .offset(x: -3, y: 5)
                                        }
                                        HStack(alignment: .top) {
                                            if fullProjData!.chatData[i].showldShowAsNew {
                                                Triangle()
                                                    .fill(Color(hex: 0x435165))
                                                    .frame(width: 8, height: 6)
                                                    .rotationEffect(.degrees(-90))
                                                    .offset(x: 10, y: 10)
                                                    .padding(0)
                                            } else {
                                                Spacer()
                                                    .frame(width: 25)
                                            }
                                            if !fullProjData!.chatData[i].isImage {
                                                BAText(fullProjData!.chatData[i].content, fontSize: 20, textColor: .white, isSystemd: true, isBold: false)
                                                    .padding(10)
                                                    .background {
                                                        RoundedRectangle(cornerRadius: 7)
                                                            .fill(Color(hex: 0x435165))
                                                    }
                                            } else {
                                                
                                            }
                                        }
                                        .offset(x: -5)
                                        .onTapGesture {
                                            if isInserting {
                                                fullProjData!.chatData.insert(.init(characterId: currentSelectCharacterData.id, imageGroupIndex: currentSelectCharacterImageGroupIndex, isImage: false, content: newMessageTextCache, showldShowAsNew: { () -> Bool in
                                                    if let upMessage = fullProjData!.chatData.last {
                                                        if upMessage.characterId == currentSelectCharacterData.id {
                                                            return false
                                                        } else {
                                                            return true
                                                        }
                                                    } else {
                                                        return true
                                                    }
                                                }()), at: i + 1)
                                                isInserting = false
                                                newMessageTextCache = ""
                                            } else {
                                                DarockKit.UIAlert.shared.presentAlert(title: "操作", subtitle: "长按以删除此对话", icon: .none, style: .iOS17AppleMusic, haptic: .warning)
                                            }
                                        }
                                        .onLongPressGesture(minimumDuration: 2) {
                                            fullProjData!.chatData.remove(at: i)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .frame(maxWidth: UIScreen.main.bounds.height - 50)
                            } else {
                                HStack {
                                    Spacer()
                                    HStack(alignment: .top) {
                                        if !fullProjData!.chatData[i].isImage {
                                            BAText(fullProjData!.chatData[i].content, fontSize: 20, textColor: .white, isSystemd: true, isBold: false)
                                                .padding(10)
                                                .background {
                                                    RoundedRectangle(cornerRadius: 7)
                                                        .fill(Color(hex: 0x417FC3))
                                                }
                                        } else {
                                            
                                        }
                                        if fullProjData!.chatData[i].showldShowAsNew {
                                            Triangle()
                                                .fill(Color(hex: 0x417FC3))
                                                .frame(width: 8, height: 6)
                                                .rotationEffect(.degrees(90))
                                                .offset(x: -10, y: 10)
                                                .padding(0)
                                        } else {
                                            Spacer()
                                                .frame(width: 16)
                                        }
                                    }
                                    .onTapGesture {
                                        if isInserting {
                                            fullProjData!.chatData.insert(.init(characterId: currentSelectCharacterData.id, imageGroupIndex: currentSelectCharacterImageGroupIndex, isImage: false, content: newMessageTextCache, showldShowAsNew: { () -> Bool in
                                                if let upMessage = fullProjData!.chatData.last {
                                                    if upMessage.characterId == currentSelectCharacterData.id {
                                                        return false
                                                    } else {
                                                        return true
                                                    }
                                                } else {
                                                    return true
                                                }
                                            }()), at: i + 1)
                                            isInserting = false
                                            newMessageTextCache = ""
                                        } else {
                                            DarockKit.UIAlert.shared.presentAlert(title: "操作", subtitle: "长按以删除此对话", icon: .none, style: .iOS17AppleMusic, haptic: .warning)
                                        }
                                    }
                                    .onLongPressGesture(minimumDuration: 2) {
                                        fullProjData!.chatData.remove(at: i)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .frame(maxWidth: UIScreen.main.bounds.height - 50)
                            }
                        }
                    } else {
                        ProgressView()
                        Text("正在载入...")
                    }
                }
                HStack {
                    TextField("消息", text: $newMessageTextCache)
                        .submitLabel(.send)
                        .onSubmit {
                            if newMessageTextCache.isContainBads && !isTippedBads {
                                isTippedBads = true
                                DarockKit.UIAlert.shared.presentAlert(title: "不适宜词汇", subtitle: "我们在您的输入中发现了可能影响蔚蓝档案二创环境的词汇\n如果这是一次误报,或您执意添加此项,请再次轻点发送按钮", icon: .heart, style: .iOS17AppleMusic, haptic: .warning, duration: 7)
                            } else {
                                fullProjData!.chatData.append(.init(characterId: currentSelectCharacterData.id, imageGroupIndex: currentSelectCharacterImageGroupIndex, isImage: false, content: newMessageTextCache, showldShowAsNew: { () -> Bool in
                                    if let upMessage = fullProjData!.chatData.last {
                                        if upMessage.characterId == currentSelectCharacterData.id {
                                            return false
                                        } else {
                                            return true
                                        }
                                    } else {
                                        return true
                                    }
                                }()))
                                newMessageTextCache = ""
                                isTippedBads = false
                            }
                        }
                    Button(action: {
                        if newMessageTextCache.isContainBads && !isTippedBads {
                            isTippedBads = true
                            DarockKit.UIAlert.shared.presentAlert(title: "不适宜词汇", subtitle: "我们在您的输入中发现了可能影响蔚蓝档案二创环境的词汇\n如果这是一次误报,或您执意添加此项,请再次轻点此按钮", icon: .heart, style: .iOS17AppleMusic, haptic: .warning, duration: 7)
                        } else {
                            isInserting.toggle()
                            isTippedBads = false
                        }
                    }, label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: 0x3D578D))
                                .frame(width: 35, height: 35)
                            Image(systemName: "text.insert")
                                .foregroundColor(.white)
                        }
                    })
                    Button(action: {
                        isChatActionsPresented = true
                    }, label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: 0x3D578D))
                                .frame(width: 35, height: 35)
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                        }
                    })
                    .sheet(isPresented: $isChatActionsPresented, onDismiss: {
                        
                    }, content: {ChatActionsView(characterSelectTab: $characterSelectTab, currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex, fullProjData: fullProjData!, projName: projName)})
                }
            }
        }
        .onAppear {
            AppDelegate.orientationLock = .portrait
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UINavigationController.attemptRotationToDeviceOrientation()
            // Wait to screen ratation Required
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                let fullFileContent = try! String(contentsOfFile: AppFileManager(path: "MTProj").GetFilePath(name: projName).path)
                fullProjData = MTBase().toFullData(byString: fullFileContent)
            }
        }
        .onDisappear {
            AppDelegate.orientationLock = .landscape
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
            UINavigationController.attemptRotationToDeviceOrientation()
        }
    }
    
    struct Triangle: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            }
        }
    }
    
    struct ChatActionsView: View {
        @Binding var characterSelectTab: [[String: Any]]?
        @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
        @Binding var currentSelectCharacterImageGroupIndex: Int
        var fullProjData: MTBase.FullData
        var projName: String
        @State var nowTabviewSelection = 0
        var body: some View {
            TabView(selection: $nowTabviewSelection) {
                CharacterSelectTabView(characterSelectTab: $characterSelectTab, currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex)
                    .tag(0)
                    .tabItem {
                        Label("对话角色库", systemImage: "rectangle.stack.badge.person.crop.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                ModifyCurrentCharacterView(characterSelectTab: $characterSelectTab, nowTabviewSelection: $nowTabviewSelection)
                    .tag(1)
                    .tabItem {
                        Label("选择角色", systemImage: "person.and.background.dotted")
                            .symbolRenderingMode(.hierarchical)
                    }
                ProjectSettingsView(fullProjData: fullProjData, projName: projName)
                    .tag(2)
                    .tabItem {
                        Label("项目管理", systemImage: "doc.badge.gearshape")
                            .symbolRenderingMode(.hierarchical)
                    }
            }
        }
        
        struct CharacterSelectTabView: View {
            @Environment(\.dismiss) var dismiss
            @Binding var characterSelectTab: [[String: Any]]?
            @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
            @Binding var currentSelectCharacterImageGroupIndex: Int
            var body: some View {
                NavigationView {
                    List {
                        Button(action: {
                            currentSelectCharacterData = MTBase.SingleCharacterData(id: "Sensei", fullName: "", shortName: "", imageNames: [""])
                            currentSelectCharacterImageGroupIndex = 0
                            dismiss()
                        }, label: {
                            HStack {
                                if currentSelectCharacterData.id == "Sensei" {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                Spacer()
                                Text("Sensei")
                            }
                        })
                        if characterSelectTab != nil {
                            ForEach(0..<characterSelectTab!.count, id: \.self) { i in
                                Button(action: {
                                    currentSelectCharacterData = characterSelectTab![i]["Character"]! as! MTBase.SingleCharacterData
                                    currentSelectCharacterImageGroupIndex = characterSelectTab![i]["ImageIndex"]! as! Int
                                    dismiss()
                                }, label: {
                                    HStack {
                                        if (characterSelectTab![i]["Character"]! as! MTBase.SingleCharacterData) == currentSelectCharacterData {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                        Image(uiImage: UIImage(data: try! Data(contentsOf: Bundle.main.url(forResource: (characterSelectTab![i]["Character"]! as! MTBase.SingleCharacterData).imageNames[characterSelectTab![i]["ImageIndex"]! as! Int], withExtension: "png")!))!)
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                        Spacer()
                                        Text((characterSelectTab![i]["Character"]! as! MTBase.SingleCharacterData).fullName)
                                    }
                                })
                            }
                        }
                    }
                    .navigationTitle("对话角色库")
                }
            }
        }
        
        struct ModifyCurrentCharacterView: View {
            @Binding var characterSelectTab: [[String: Any]]?
            @Binding var nowTabviewSelection: Int
            @State var allCharacterDatas: [MTBase.SingleCharacterData]? = nil
            var body: some View {
                NavigationView {
                    List {
                        if allCharacterDatas != nil {
                            ForEach(0..<allCharacterDatas!.count, id: \.self) { i in
                                NavigationLink(destination: {AddCharacterSettingView(selectedCharacterData: allCharacterDatas![i], characterSelectTab: $characterSelectTab, nowTabviewSelection: $nowTabviewSelection)}, label: {
                                    HStack {
                                        Image(uiImage: UIImage(data: try! Data(contentsOf: Bundle.main.url(forResource: allCharacterDatas![i].imageNames[0], withExtension: "png")!))!)
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                        Spacer()
                                        Text(allCharacterDatas![i].fullName)
                                    }
                                })
                            }
                        }
                    }
                    .navigationTitle("选择角色")
                    .onAppear {
                        allCharacterDatas = MTBase().getAllCharacterDatas()
                    }
                }
            }
            
            struct AddCharacterSettingView: View {
                var selectedCharacterData: MTBase.SingleCharacterData
                @Binding var characterSelectTab: [[String: Any]]?
                @Binding var nowTabviewSelection: Int
                @Environment(\.dismiss) var dismiss
                @State var selectedImageIndex = 0
                var body: some View {
                    List {
                        Section {
                            ForEach(0..<selectedCharacterData.imageNames.count, id: \.self) { i in
                                Button(action: {
                                    selectedImageIndex = i
                                }, label: {
                                    HStack {
                                        if selectedImageIndex == i {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                        Image(uiImage: UIImage(data: try! Data(contentsOf: Bundle.main.url(forResource: selectedCharacterData.imageNames[i], withExtension: "png")!))!)
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                        Spacer()
                                        Text("头像 #\(i + 1)")
                                    }
                                })
                            }
                        }
                        Section {
                            Button(action: {
                                if characterSelectTab == nil {
                                    characterSelectTab = [[String: Any]]()
                                }
                                characterSelectTab!.append(["Character": selectedCharacterData, "ImageIndex": selectedImageIndex])
                                nowTabviewSelection = 0
                                DarockKit.UIAlert.shared.presentAlert(title: "添加成功", subtitle: "已将\(selectedCharacterData.shortName)添加到对话角色库", icon: .done, style: .iOS17AppleMusic, haptic: .success)
                            }, label: {
                                Text("添加")
                            })
                        }
                    }
                    .navigationTitle("选择")
                    .onAppear {
                        
                    }
                }
            }
        }
        
        struct ProjectSettingsView: View {
            var fullProjData: MTBase.FullData
            var projName: String
            var body: some View {
                NavigationView {
                    List {
                        Section(header: Text("操作")) {
                            Button(action: {
                                SaveProject()
                                DarockKit.UIAlert.shared.presentAlert(title: "成功", subtitle: "项目已保存", icon: .done, style: .iOS17AppleMusic, haptic: .success)
                            }, label: {
                                Text("保存")
                            })
                            Button(action: {
                                SaveProject()
                                nowScene = .MTEditChooser
                            }, label: {
                                Text("保存并退出")
                            })
                            Button(role: .destructive, action: {
                                DarockKit.UIAlert.shared.presentAlert(title: "需要确认", subtitle: "长按文字以执行此操作", icon: .none, style: .iOS17AppleMusic, haptic: .warning)
                            }, label: {
                                HStack {
                                    Text("退出但不保存")
                                    Spacer()
                                }
                            })
                            .onTapGesture {
                                DarockKit.UIAlert.shared.presentAlert(title: "需要确认", subtitle: "长按文字以执行此操作", icon: .none, style: .iOS17AppleMusic, haptic: .warning)
                            }
                            .onLongPressGesture(minimumDuration: 2.5) {
                                nowScene = .MTEditChooser
                            }
                            Button(role: .destructive, action: {
                                DarockKit.UIAlert.shared.presentAlert(title: "需要确认", subtitle: "长按文字以执行此操作", icon: .none, style: .iOS17AppleMusic, haptic: .warning)
                            }, label: {
                                HStack {
                                    Text("删除此项目")
                                    Spacer()
                                }
                            })
                            .onTapGesture {
                                DarockKit.UIAlert.shared.presentAlert(title: "需要确认", subtitle: "长按文字以执行此操作", icon: .none, style: .iOS17AppleMusic, haptic: .warning)
                            }
                            .onLongPressGesture(minimumDuration: 2.5) {
                                AppFileManager(path: "MTProj").DeleteFile(projName)
                                nowScene = .MTEditChooser
                            }
                        }
                    }
                    .navigationTitle("项目管理")
                }
            }
            
            func SaveProject() {
                let projStrData = MTBase().toOutString(from: fullProjData)
                let filePath = AppFileManager(path: "MTProj").GetFilePath(name: projName).path
                try! projStrData.write(toFile: filePath, atomically: true, encoding: .utf8)
            }
        }
    }
}

// MARK: MTClass
class MTBase {
    struct FullData {
        var chatData: [SingleChatData]
    }
    struct SingleChatData: Identifiable {
        var id: UUID = UUID()
        
        var characterId: String
        var imageGroupIndex: Int
        var isImage: Bool
        var content: String
        var showldShowAsNew: Bool
    }
    struct SingleCharacterData: Identifiable, Equatable {
        let id: String
        let fullName: String
        let shortName: String
        let imageNames: [String]
    }
    
    func toFullData(byString inp: String) -> FullData {
        var tmpChatData = [SingleChatData]()
        let inpLined = inp.split(separator: "\n").map { return String($0) }
        for lineData in inpLined {
            let dataSpd = lineData.split(separator: "|").map { return String($0) }
            guard dataSpd.count == 4 else {
                break
            }
            if let imgGroupIndex = Int(dataSpd[1]),
               let isShowldShowAsNew = Bool(dataSpd[3]) {
                let isImage = dataSpd[2].hasPrefix("%%TImage%%*")
                tmpChatData.append(SingleChatData(characterId: dataSpd[0], imageGroupIndex: imgGroupIndex, isImage: isImage, content: isImage ? String(dataSpd[2].dropFirst(11)) : dataSpd[2], showldShowAsNew: isShowldShowAsNew))
            }
        }
        return FullData(chatData: tmpChatData)
    }
    func toOutString(from inp: FullData) -> String {
        let chatData = inp.chatData
        var tmpOutStr = ""
        for singleChat in chatData {
            tmpOutStr += "\(singleChat.characterId)|\(singleChat.imageGroupIndex)|\(singleChat.isImage ? "%%TImage%%*" : "")\(singleChat.content)|\(singleChat.showldShowAsNew)\n"
        }
        return tmpOutStr
    }
    func getCharacterData(byId id: String) -> SingleCharacterData? {
        let json = try! JSON(data: Data(contentsOf: Bundle.main.url(forResource: "MTCharacterData", withExtension: "json")!))
        for character in json {
            if character.1["id"].string! == id {
                return SingleCharacterData(id: id, fullName: character.1["names"]["zh-cn"].string!, shortName: character.1["short_names"]["zh-cn"].string!, imageNames: character.1["images"].arrayObject! as! [String])
            }
        }
        return nil
    }
    func getAllCharacterDatas() -> [SingleCharacterData] {
        let json = try! JSON(data: Data(contentsOf: Bundle.main.url(forResource: "MTCharacterData", withExtension: "json")!))
        var tmpOutDatas = [SingleCharacterData]()
        for character in json {
            tmpOutDatas.append(SingleCharacterData(id: character.1["id"].string!, fullName: character.1["names"]["zh-cn"].string!, shortName: character.1["short_names"]["zh-cn"].string!, imageNames: character.1["images"].arrayObject! as! [String]))
        }
        return tmpOutDatas
    }
}

func base64ToImage(from inp: String) -> UIImage? {
    let dataDecoded = Data(base64Encoded: inp, options: NSData.Base64DecodingOptions(rawValue: 0))!
    let decodedimage = UIImage(data: dataDecoded)
    return decodedimage
}

#Preview {
    MTEditorView()
}
