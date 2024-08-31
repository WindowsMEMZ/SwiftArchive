//
//  MTEditorView.swift
//  BAGen
//
//  Created by memz233 on 2023/10/5.
//

import SwiftUI
import PhotosUI
import DarockKit
import SwiftyJSON
import SwiftyCrop
import ScreenshotableView
import SwiftVideoGenerator

// 文件格式:
// 文本对话: {角色 ID(String)}|{头像组下标(Int)}|{内容}|{ShouldShowAsNew(Bool)}
// 图片:    {角色 ID(String)}|{头像组下标(Int)}|"%%TImage%%*"(图像标记){图像 Base64|图像路径(./开头)}|{ShouldShowAsNew(Bool)}
// 按行分隔
// 角色 ID 为 "Sensei" 时显示消息由我方发出
// 角色 ID 为 "SpecialEvent" 时显示羁绊剧情, 此时内容为羁绊剧情对象
// 角色 ID 为 "System" 时显示系统信息

//!!!: On this view, UIScreen.main.bounds' height & width were exchanged
struct MTEditorView: View {
    var projName: String = mtEnterProjName
    @Environment(\.dismiss) var dismiss
    @FocusState var messageInputFocusState
    @Namespace var chatScrollLastItem
    @AppStorage("IsAutoSave") var autoSave = true
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
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        if fullProjData != nil {
                            MainChatsView(projName: projName, fullProjData: $fullProjData, newMessageTextCache: $newMessageTextCache, currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex, isInserting: $isInserting)
                                .onAppear {
                                    scrollProxy.scrollTo(chatScrollLastItem)
                                }
                        } else {
                            ProgressView()
                            Text("正在载入...")
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    HStack {
                        TextField("消息", text: $newMessageTextCache)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.send)
                            .onSubmit {
                                if newMessageTextCache.isContainBads && !isTippedBads {
                                    isTippedBads = true
                                    DarockKit.UIAlert.shared.presentAlert(title: "不适宜词汇", subtitle: "我们在您的输入中发现了可能影响蔚蓝档案二创环境的词汇\n如果这是一次误报,或您执意添加此项,请再次轻点发送按钮", icon: .heart, style: .iOS17AppleMusic, haptic: .warning, duration: 7)
                                } else {
                                    let shouldShowAsNew = { () -> Bool in
                                        if let upMessage = fullProjData!.chatData.last {
                                            if upMessage.characterId == currentSelectCharacterData.id {
                                                return false
                                            } else {
                                                return true
                                            }
                                        } else {
                                            return true
                                        }
                                    }()
                                    if !currentSelectCharacterData.id.hasPrefix("SACustom") {
                                        fullProjData!.chatData.append(.init(characterId: currentSelectCharacterData.id, imageGroupIndex: currentSelectCharacterImageGroupIndex, isImage: false, content: newMessageTextCache, shouldShowAsNew: shouldShowAsNew))
                                    } else {
                                        fullProjData!.chatData.append(.init(characterId: "\(currentSelectCharacterData.fullName)%^Split^@\(currentSelectCharacterData.imageNames[0])", imageGroupIndex: currentSelectCharacterImageGroupIndex, isImage: false, content: newMessageTextCache, shouldShowAsNew: shouldShowAsNew))
                                    }
                                    newMessageTextCache = ""
                                    isTippedBads = false
                                    mtIsHaveUnsavedChange = true
                                    if autoSave {
                                        SaveProject()
                                    }
                                }
                            }
                            .focused($messageInputFocusState)
                            .onChange(of: messageInputFocusState) {
                                if messageInputFocusState {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        withAnimation {
                                            scrollProxy.scrollTo(fullProjData!.chatData.count - 1)
                                        }
                                    }
                                }
                            }
                        Button(action: {
                            if newMessageTextCache.isContainBads && !isTippedBads {
                                isTippedBads = true
                                DarockKit.UIAlert.shared.presentAlert(title: "不适宜词汇", subtitle: "我们在您的输入中发现了可能影响蔚蓝档案二创环境的词汇\n如果这是一次误报,或您执意添加此项,请再次轻点此按钮", icon: .heart, style: .iOS17AppleMusic, haptic: .warning, duration: 7)
                            } else {
                                isInserting.toggle()
                                isTippedBads = false
                                mtIsHaveUnsavedChange = true
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
                            
                        }, content: {
                            ChatActionsView(characterSelectTab: $characterSelectTab, currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex, fullProjData: $fullProjData, projName: projName, dismissAction: dismiss)
                        })
                    }
                    .padding(.horizontal)
                    .disabled(fullProjData == nil)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                let fullFileContent = try! String(contentsOfFile: AppFileManager(path: "MTProj").GetFilePath(name: projName).path)
                fullProjData = MTBase().toFullData(byString: fullFileContent)
            }
        }
        .onDisappear {
            if autoSave {
                SaveProject()
            }
            mtIsHaveUnsavedChange = false
        }
    }
    
    func SaveProject() {
        let projStrData = MTBase().toOutString(from: fullProjData!)
        let filePath = AppFileManager(path: "MTProj").GetFilePath(name: projName).path
        try! projStrData.write(toFile: filePath, atomically: true, encoding: .utf8)
        mtIsHaveUnsavedChange = false
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
    
    struct MainChatsView: View {
        var projName: String
        @Binding var fullProjData: MTBase.FullData?
        @Binding var newMessageTextCache: String
        @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
        @Binding var currentSelectCharacterImageGroupIndex: Int
        @Binding var isInserting: Bool
        var displayMessageIndexRange: ClosedRange<Int>? = nil // For ScreenShot
        @Namespace var chatScrollLastItem
        @AppStorage("IsAutoSave") var autoSave = true
        var body: some View {
            VStack {
                Spacer()
                    .frame(height: 5)
                ForEach(0..<fullProjData!.chatData.count, id: \.self) { i in
                    if displayMessageIndexRange == nil || (displayMessageIndexRange ?? 0...1).contains(i) {
                        Group {
                            if fullProjData!.chatData[i].characterId == "Sensei" {
                                // MARK: Message View from Sensei
                                HStack {
                                    Spacer()
                                    HStack(alignment: .top) {
                                        if !fullProjData!.chatData[i].isImage {
                                            BAText(fullProjData!.chatData[i].content, fontSize: 18, textColor: .white, isSystemd: true, isBold: false)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .padding(10)
                                                .background {
                                                    RoundedRectangle(cornerRadius: 7)
                                                        .fill(Color(hex: 0x417FC3))
                                                }
                                        } else {
                                            if fullProjData!.chatData[i].content.hasPrefix("./"),
                                               let image = UIImage(contentsOfFile: Bundle.main.bundlePath + fullProjData!.chatData[i].content.dropFirst()) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 150)
                                                    .cornerRadius(8)
                                                    .padding(6)
                                                    .background {
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(Color.white)
                                                            .strokeBorder(Color(hex: 0xc6cdd7), lineWidth: 1.5)
                                                    }
                                            } else if let imgData = Data(base64Encoded: fullProjData!.chatData[i].content), let image = UIImage(data: imgData) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 150)
                                                    .cornerRadius(8)
                                                    .padding(6)
                                                    .background {
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(Color.white)
                                                            .strokeBorder(Color(hex: 0xc6cdd7), lineWidth: 1.5)
                                                    }
                                            }
                                        }
                                        if fullProjData!.chatData[i].shouldShowAsNew && !fullProjData!.chatData[i].isImage {
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
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .frame(maxWidth: UIScreen.main.bounds.height - 50)
                            } else if fullProjData!.chatData[i].characterId == "SpecialEvent" {
                                // MARK: Special Event Message View
                                HStack {
                                    Spacer()
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(hex: 0xfaedf0))
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color(hex: 0xCDCDCD), lineWidth: 1)
                                            }
                                            .frame(width: 220, height: 80)
                                        HStack {
                                            Spacer()
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 88))
                                                .foregroundColor(Color(hex: 0xf7d2db))
                                                .clipped()
                                                .mask(alignment: .leading, { Rectangle().frame(width: 85) })
                                                .offset(x: 22)
                                        }
                                        VStack {
                                            HStack {
                                                Capsule()
                                                    .fill(Color(hex: 0xd89ea9))
                                                    .frame(width: 2, height: 18)
                                                BAText("羁绊事件", fontSize: 15, isSystemd: true)
                                                Spacer()
                                            }
                                            Capsule()
                                                .fill(Color.gray)
                                                .frame(height: 1)
                                            Button(action: {
                                                
                                            }, label: {
                                                HStack {
                                                    Spacer()
                                                    BAText("前往\(fullProjData!.chatData[i].content)的羁绊剧情", fontSize: 15, textColor: .white, isSystemd: true, isBold: false)
                                                    Spacer()
                                                }
                                            })
                                            .padding(.vertical, 8)
                                            .background {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(hex: 0xec95a3))
                                                    .shadow(radius: 5)
                                            }
                                        }
                                        .padding()
                                    }
                                    .frame(width: 220, height: 80)
                                    Spacer()
                                        .frame(width: 15)
                                }
                            } else if fullProjData!.chatData[i].characterId == "System" {
                                // MARK: Message View from System
                                HStack {
                                    Spacer()
                                    BAText(fullProjData!.chatData[i].content, fontSize: 16, textColor: Color(hex: 0x3C454F), isSystemd: true)
                                    Spacer()
                                }
                            } else {
                                // MARK: Other Character Message View
                                HStack(alignment: .top) {
                                    let thisCharacterData = {
                                        if !fullProjData!.chatData[i].characterId.contains("%^Split^@") {
                                            return MTBase().getCharacterData(byId: fullProjData!.chatData[i].characterId)!
                                        } else {
                                            let spd = fullProjData!.chatData[i].characterId.components(separatedBy: "%^Split^@")
                                            return MTBase.SingleCharacterData(id: "SACustom", fullName: spd[0], shortName: spd[0], imageNames: [spd[1]])
                                        }
                                    }()
                                    if fullProjData!.chatData[i].shouldShowAsNew {
                                        Group {
                                            if !thisCharacterData.id.hasPrefix("SACustom") {
                                                Image(uiImage: UIImage(data: try! Data(contentsOf: Bundle.main.url(forResource: thisCharacterData.imageNames[fullProjData!.chatData[i].imageGroupIndex], withExtension: "webp")!))!)
                                                    .resizable()
                                            } else {
                                                if let image = base64ToImage(from: thisCharacterData.imageNames[0]) {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                }
                                            }
                                        }
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.clear)
                                            .frame(width: 50, height: 50)
                                    }
                                    VStack {
                                        // Character Name
                                        if fullProjData!.chatData[i].shouldShowAsNew {
                                            HStack {
                                                BAText(thisCharacterData.shortName, fontSize: 16, isSystemd: true)
                                                    .padding(0)
                                                    .offset(x: 3, y: 5)
                                                Spacer()
                                            }
                                        }
                                        HStack(alignment: .top) {
                                            // Message Bubble
                                            if fullProjData!.chatData[i].shouldShowAsNew && !fullProjData!.chatData[i].isImage {
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
                                                // Text Content
                                                BAText(fullProjData!.chatData[i].content, fontSize: 18, textColor: .white, isSystemd: true, isBold: false)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .padding(10)
                                                    .background {
                                                        RoundedRectangle(cornerRadius: 7)
                                                            .fill(Color(hex: 0x435165))
                                                    }
                                            } else {
                                                if fullProjData!.chatData[i].content.hasPrefix("./"),
                                                   let image = UIImage(contentsOfFile: Bundle.main.bundlePath + fullProjData!.chatData[i].content.dropFirst()) {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 150)
                                                        .cornerRadius(8)
                                                        .padding(6)
                                                        .background {
                                                            RoundedRectangle(cornerRadius: 12)
                                                                .fill(Color.white)
                                                                .strokeBorder(Color(hex: 0xc6cdd7), lineWidth: 1.5)
                                                        }
                                                } else if let imgData = Data(base64Encoded: fullProjData!.chatData[i].content), let image = UIImage(data: imgData) {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 150)
                                                        .cornerRadius(8)
                                                        .padding(6)
                                                        .background {
                                                            RoundedRectangle(cornerRadius: 12)
                                                                .fill(Color.white)
                                                                .strokeBorder(Color(hex: 0xc6cdd7), lineWidth: 1.5)
                                                        }
                                                }
                                            }
                                            Spacer()
                                        }
                                        .offset(x: -10)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, -3)
                                .frame(maxWidth: UIScreen.main.bounds.height - 50)
                            }
                        }
                        .onTapGesture {
                            if isInserting {
                                let shouldShowAsNew = { () -> Bool in
                                    if let upMessage = fullProjData!.chatData.last {
                                        if upMessage.characterId == currentSelectCharacterData.id {
                                            return false
                                        } else {
                                            return true
                                        }
                                    } else {
                                        return true
                                    }
                                }()
                                if !currentSelectCharacterData.id.hasPrefix("SACustom") {
                                    fullProjData!.chatData.insert(.init(characterId: currentSelectCharacterData.id, imageGroupIndex: currentSelectCharacterImageGroupIndex, isImage: false, content: newMessageTextCache, shouldShowAsNew: shouldShowAsNew), at: i + 1)
                                } else {
                                    fullProjData!.chatData.insert(.init(characterId: "\(currentSelectCharacterData.fullName)%^Split^@\(currentSelectCharacterData.imageNames[0])", imageGroupIndex: currentSelectCharacterImageGroupIndex, isImage: false, content: newMessageTextCache, shouldShowAsNew: shouldShowAsNew), at: i + 1)
                                }
                                isInserting = false
                                newMessageTextCache = ""
                                if autoSave {
                                    SaveProject()
                                }
                            } else {
                                DarockKit.UIAlert.shared.presentAlert(title: "操作", subtitle: "长按以删除此对话", icon: .none, style: .iOS17AppleMusic, haptic: .warning)
                            }
                        }
                        .onLongPressGesture(minimumDuration: 2) {
                            fullProjData!.chatData.remove(at: i)
                            if autoSave {
                                SaveProject()
                            }
                        }
                        .id(i)
                    }
                }
                Spacer()
                    .frame(height: 5)
                    .id(chatScrollLastItem)
            }
            .background(Color(hex: 0xFFF6DD))
        }
        
        func SaveProject() {
            let projStrData = MTBase().toOutString(from: fullProjData!)
            let filePath = AppFileManager(path: "MTProj").GetFilePath(name: projName).path
            try! projStrData.write(toFile: filePath, atomically: true, encoding: .utf8)
            mtIsHaveUnsavedChange = false
        }
    }
    
    struct ChatActionsView: View {
        @Binding var characterSelectTab: [[String: Any]]?
        @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
        @Binding var currentSelectCharacterImageGroupIndex: Int
        @Binding var fullProjData: MTBase.FullData?
        var projName: String
        var dismissAction: DismissAction
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
                SendSpecialMessageView(currentSelectCharacterData: $currentSelectCharacterData, fullProjData: $fullProjData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex)
                    .tag(2)
                    .tabItem {
                        Label("特殊消息", systemImage: "star.bubble")
                            .symbolRenderingMode(.hierarchical)
                    }
                ProjectSettingsView(projName: projName, dismissAction: dismissAction, fullProjData: $fullProjData, currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex)
                    .tag(3)
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
                NavigationStack {
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
                                        Group {
                                            if !(characterSelectTab![i]["Character"]! as! MTBase.SingleCharacterData).id.hasPrefix("SACustom") {
                                                Image(uiImage: UIImage(data: try! Data(contentsOf: Bundle.main.url(forResource: (characterSelectTab![i]["Character"]! as! MTBase.SingleCharacterData).imageNames[characterSelectTab![i]["ImageIndex"]! as! Int], withExtension: "webp")!))!)
                                                    .resizable()
                                            } else {
                                                if let image = base64ToImage(from: (characterSelectTab![i]["Character"]! as! MTBase.SingleCharacterData).imageNames[0]) {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                }
                                            }
                                        }
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
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                dismiss()
                            }, label: {
                                Image(systemName: "xmark")
                                    .bold()
                                    .foregroundStyle(Color.gray)
                            })
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.circle)
                        }
                    }
                }
            }
        }
        
        struct ModifyCurrentCharacterView: View {
            @Binding var characterSelectTab: [[String: Any]]?
            @Binding var nowTabviewSelection: Int
            @Environment(\.dismiss) var dismiss
            @State var allCharacterDatas: [MTBase.SingleCharacterData]?
            @State var searchText = ""
            @State var searchedCharacterDatas: [MTBase.SingleCharacterData]?
            @State var customCharacters = [MTBase.SingleCharacterData]()
            var body: some View {
                NavigationStack {
                    List {
                        Section {
                            NavigationLink(destination: { AddCustomCharacterView() }, label: {
                                HStack {
                                    Image(systemName: "plus")
                                        .foregroundStyle(Color.blue)
                                    Spacer()
                                    Text("添加自定角色")
                                }
                            })
                            if !customCharacters.isEmpty {
                                ForEach(0..<customCharacters.count, id: \.self) { i in
                                    Button(action: {
                                        if characterSelectTab == nil {
                                            characterSelectTab = [[String: Any]]()
                                        }
                                        characterSelectTab!.append(["Character": customCharacters[i], "ImageIndex": 0])
                                        nowTabviewSelection = 0
                                        DarockKit.UIAlert.shared.presentAlert(title: "添加成功", subtitle: "已将\(customCharacters[i].shortName)添加到对话角色库", icon: .done, style: .iOS17AppleMusic, haptic: .success)
                                    }, label: {
                                        HStack {
                                            if let image = base64ToImage(from: customCharacters[i].imageNames[0]) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .frame(width: 50, height: 50)
                                                    .clipShape(Circle())
                                            }
                                            Spacer()
                                            Text(customCharacters[i].fullName)
                                                .foregroundStyle(Color.black)
                                        }
                                    })
                                    .swipeActions {
                                        Button(role: .destructive, action: {
                                            do {
                                                try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/CustomCharacters/\(customCharacters[i].id.dropFirst(8)).cc")
                                                refreshCustomCharacters()
                                            } catch {
                                                print(error)
                                            }
                                        }, label: {
                                            Image(systemName: "xmark.bin.fill")
                                        })
                                    }
                                }
                            }
                        } header: {
                            Text("自定角色")
                        }
                        if allCharacterDatas != nil {
                            Section {
                                if searchText == "" || searchedCharacterDatas == nil || searchedCharacterDatas?.count == 0 {
                                    ForEach(0..<allCharacterDatas!.count, id: \.self) { i in
                                        NavigationLink(destination: { AddCharacterSettingView(selectedCharacterData: allCharacterDatas![i], characterSelectTab: $characterSelectTab, nowTabviewSelection: $nowTabviewSelection) }, label: {
                                            HStack {
                                                Image(uiImage: UIImage(data: try! Data(contentsOf: Bundle.main.url(forResource: allCharacterDatas![i].imageNames[0], withExtension: "webp")!))!)
                                                    .resizable()
                                                    .frame(width: 50, height: 50)
                                                    .clipShape(Circle())
                                                Spacer()
                                                Text(allCharacterDatas![i].fullName)
                                            }
                                        })
                                    }
                                } else {
                                    ForEach(0..<searchedCharacterDatas!.count, id: \.self) { i in
                                        NavigationLink(destination: { AddCharacterSettingView(selectedCharacterData: searchedCharacterDatas![i], characterSelectTab: $characterSelectTab, nowTabviewSelection: $nowTabviewSelection) }, label: {
                                            HStack {
                                                Image(uiImage: UIImage(data: try! Data(contentsOf: Bundle.main.url(forResource: searchedCharacterDatas![i].imageNames[0], withExtension: "webp")!))!)
                                                    .resizable()
                                                    .frame(width: 50, height: 50)
                                                    .clipShape(Circle())
                                                Spacer()
                                                Text(searchedCharacterDatas![i].fullName)
                                            }
                                        })
                                    }
                                }
                            } header: {
                                Text("官方角色")
                            }
                        }
                    }
                    .navigationTitle("选择角色")
                    .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "搜索...")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                dismiss()
                            }, label: {
                                Image(systemName: "xmark")
                                    .bold()
                                    .foregroundStyle(Color.gray)
                            })
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.circle)
                        }
                    }
                    .onAppear {
                        allCharacterDatas = MTBase().getAllCharacterDatas()
                        refreshCustomCharacters()
                    }
                    .onChange(of: searchText) {
                        searchedCharacterDatas = [MTBase.SingleCharacterData]()
                        for i in 0..<allCharacterDatas!.count {
                            if allCharacterDatas![i].fullName.contains(searchText) {
                                searchedCharacterDatas!.append(allCharacterDatas![i])
                            }
                        }
                    }
                }
            }
            func refreshCustomCharacters() {
                do {
                    let customs = try FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Documents/CustomCharacters")
                    customCharacters.removeAll()
                    for fileName in customs {
                        if let data = try? String(contentsOfFile: NSHomeDirectory() + "/Documents/CustomCharacters/\(fileName)", encoding: .utf8),
                           let charaData = getJsonData(MTBase.SingleCharacterData.self, from: data) {
                            customCharacters.append(charaData)
                        }
                    }
                } catch {
                    print(error)
                }
            }
            
            struct AddCustomCharacterView: View {
                @Environment(\.dismiss) var dismiss
                @State var selectedAvator: PhotosPickerItem?
                @State var isPhotoPickerPresented = false
                @State var cropAvator: UIImage?
                @State var resultAvator: UIImage?
                @State var isImageCropperPresented = false
                @State var nameInput = ""
                var body: some View {
                    List {
                        Section {
                            Group {
                                if let resultAvator {
                                    Image(uiImage: resultAvator)
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    VStack {
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundStyle(Color.blue)
                                        Text("轻触以选择头像...")
                                            .font(.system(size: 14))
                                    }
                                }
                            }
                            .centerAligned()
                            .onTapGesture {
                                isPhotoPickerPresented = true
                            }
                        }
                        .listRowBackground(Color.clear)
                        Section {
                            TextField("角色名...", text: $nameInput)
                        }
                    }
                    .navigationTitle("自定角色")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                do {
                                    if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/CustomCharacters") {
                                        try FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Documents/CustomCharacters", withIntermediateDirectories: true)
                                    }
                                    let uuid = UUID().uuidString
                                    if let str = jsonString(from: MTBase.SingleCharacterData(id: "SACustom\(uuid)", fullName: nameInput, shortName: nameInput, imageNames: [resultAvator!.pngData()!.base64EncodedString()])) {
                                        try str.write(toFile: NSHomeDirectory() + "/Documents/CustomCharacters/\(uuid).cc", atomically: true, encoding: .utf8)
                                        dismiss()
                                    }
                                } catch {
                                    print(error)
                                }
                            }, label: {
                                Image(systemName: "plus")
                            })
                            .disabled(resultAvator == nil || nameInput.isEmpty)
                        }
                    }
                    .photosPicker(isPresented: $isPhotoPickerPresented, selection: $selectedAvator, matching: .images)
                    .fullScreenCover(isPresented: $isImageCropperPresented) {
                        NavigationView {
                            SwiftyCropView(imageToCrop: cropAvator!, maskShape: .circle) { croppedImage in
                                resultAvator = croppedImage
                            }
                        }
                    }
                    .onChange(of: selectedAvator) {
                        if let selectedAvator {
                            selectedAvator.loadTransferable(type: UIImageTransfer.self) { result in
                                if case .success(let dataTransfer) = result, let image = dataTransfer {
                                    cropAvator = image.image
                                }
                            }
                        }
                    }
                    .onChange(of: cropAvator) {
                        if cropAvator != nil {
                            isImageCropperPresented = true
                        }
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
                                        Image(uiImage: UIImage(data: try! Data(contentsOf: Bundle.main.url(forResource: selectedCharacterData.imageNames[i], withExtension: "webp")!))!)
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
        
        struct SendSpecialMessageView: View {
            @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
            @Binding var fullProjData: MTBase.FullData?
            @Binding var currentSelectCharacterImageGroupIndex: Int
            @Environment(\.dismiss) var dismiss
            @AppStorage("IsIgnoreSpecialEventTip") var isIgnoreSpecialEventTip = false
            @State var systemMessageInputCache = ""
            @State var shouldAddSpecialEvent = false
            @State var isSpecialEventAddTipPresented = false
            @State var isCharaImgsDownloadPresented = false
            @State var importSelectedPhoto: PhotosPickerItem?
            var body: some View {
                NavigationStack {
                    List {
                        Section {
                            TextField("系统消息", text: $systemMessageInputCache)
                                .onSubmit {
                                    fullProjData!.chatData.append(.init(characterId: "System", imageGroupIndex: 0, isImage: false, content: systemMessageInputCache, shouldShowAsNew: true))
                                    systemMessageInputCache = ""
                                    dismiss()
                                }
                            NavigationLink(destination: { DiffAvatorChooseView(currentSelectCharacterData: $currentSelectCharacterData, fullProjData: $fullProjData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex, dismissSheet: dismiss) }, label: {
                                Text("差分表情图片...")
                            })
                            PhotosPicker(selection: $importSelectedPhoto, matching: .images) {
                                Text("自选图片...")
                            }
                            if currentSelectCharacterData.id != "Sensei" {
                                Button(action: {
                                    if !isIgnoreSpecialEventTip {
                                        isSpecialEventAddTipPresented = true
                                    } else {
                                        AddNewSpecialEvent()
                                        dismiss()
                                    }
                                }, label: {
                                    Text("\(currentSelectCharacterData.shortName)的羁绊剧情")
                                })
                                .sheet(isPresented: $isSpecialEventAddTipPresented, onDismiss: {
                                    if shouldAddSpecialEvent {
                                        shouldAddSpecialEvent = false
                                        AddNewSpecialEvent()
                                        dismiss()
                                    }
                                }, content: {SpecialEventAddTipView(shouldAddSpecialEvent: $shouldAddSpecialEvent)})
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .navigationTitle("特殊消息")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                dismiss()
                            }, label: {
                                Image(systemName: "xmark")
                                    .bold()
                                    .foregroundStyle(Color.gray)
                            })
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.circle)
                        }
                    }
                    .onChange(of: importSelectedPhoto) {
                        importSelectedPhoto?.loadTransferable(type: UIImageTransfer.self) { result in
                            switch result {
                            case .success(let success):
                                if let image = success {
                                    let imgBase64 = image.image.pngData()!.base64EncodedString()
                                    if !currentSelectCharacterData.id.hasPrefix("SACustom") {
                                        fullProjData!.chatData.append(.init(characterId: currentSelectCharacterData.id, imageGroupIndex: currentSelectCharacterImageGroupIndex, isImage: true, content: imgBase64, shouldShowAsNew: true))
                                    } else {
                                        fullProjData!.chatData.append(.init(characterId: "\(currentSelectCharacterData.fullName)%^Split^@\(currentSelectCharacterData.imageNames[0])", imageGroupIndex: currentSelectCharacterImageGroupIndex, isImage: false, content: imgBase64, shouldShowAsNew: true))
                                    }
                                }
                            case .failure(let error):
                                print(error)
                            }
                        }
                    }
                }
            }
            
            func AddNewSpecialEvent() {
                fullProjData!.chatData.append(.init(characterId: "SpecialEvent", imageGroupIndex: 0, isImage: false, content: currentSelectCharacterData.shortName, shouldShowAsNew: true))
            }
            
            struct DiffAvatorChooseView: View {
                @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
                @Binding var fullProjData: MTBase.FullData?
                @Binding var currentSelectCharacterImageGroupIndex: Int
                var dismissSheet: DismissAction
                @State var schools = [String]()
                var body: some View {
                    List {
                        Section {
                            if !schools.isEmpty {
                                ForEach(0..<schools.count, id: \.self) { i in
                                    NavigationLink(destination: { CharacterChooseView(currentSelectCharacterData: $currentSelectCharacterData, fullProjData: $fullProjData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex, dismissSheet: dismissSheet, choseSchoolName: schools[i]) }, label: {
                                        Text(schools[i])
                                    })
                                }
                            }
                        } footer: {
                            Text("差分图片来自朝禊ASOGI的《基沃托斯差分立绘补完计划》")
                        }
                    }
                    .navigationTitle("选择差分表情 - 学院")
                    .onAppear {
                        do {
                            schools = try FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundleURL.appending(path: "AvatorDiffs").path())
                        } catch {
                            print(error)
                        }
                    }
                }
                
                struct CharacterChooseView: View {
                    @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
                    @Binding var fullProjData: MTBase.FullData?
                    @Binding var currentSelectCharacterImageGroupIndex: Int
                    var dismissSheet: DismissAction
                    var choseSchoolName: String
                    @State var characters = [String]()
                    @State var searchText = ""
                    var body: some View {
                        List {
                            Section {
                                if !characters.isEmpty {
                                    ForEach(0..<characters.count, id: \.self) { i in
                                        if searchText.isEmpty || characters[i].contains(searchText) {
                                            NavigationLink(destination: { ImageChooseView(currentSelectCharacterData: $currentSelectCharacterData, fullProjData: $fullProjData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex, dismissSheet: dismissSheet, choseSchoolName: choseSchoolName, choseCharacterName: characters[i]) }, label: {
                                                Text(characters[i])
                                            })
                                        }
                                    }
                                }
                            }
                        }
                        .searchable(text: $searchText)
                        .navigationTitle("选择差分表情 - 学生")
                        .onAppear {
                            do {
                                characters = try FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath + "/AvatorDiffs/\(choseSchoolName)")
                            } catch {
                                print(error)
                            }
                        }
                    }
                    
                    struct ImageChooseView: View {
                        @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
                        @Binding var fullProjData: MTBase.FullData?
                        @Binding var currentSelectCharacterImageGroupIndex: Int
                        var dismissSheet: DismissAction
                        var choseSchoolName: String
                        var choseCharacterName: String
                        @State var images = [String]()
                        var body: some View {
                            List {
                                Section {
                                    if !images.isEmpty {
                                        ForEach(0..<images.count, id: \.self) { i in
                                            Button(action: {
                                                if !currentSelectCharacterData.id.hasPrefix("SACustom") {
                                                    fullProjData!.chatData.append(.init(characterId: currentSelectCharacterData.id, imageGroupIndex: currentSelectCharacterImageGroupIndex, isImage: true, content: "./AvatorDiffs/\(choseSchoolName)/\(choseCharacterName)/\(images[i])", shouldShowAsNew: true))
                                                } else {
                                                    fullProjData!.chatData.append(.init(characterId: "\(currentSelectCharacterData.fullName)%^Split^@\(currentSelectCharacterData.imageNames[0])", imageGroupIndex: currentSelectCharacterImageGroupIndex, isImage: false, content: "./AvatorDiffs/\(choseSchoolName)/\(choseCharacterName)/\(images[i])", shouldShowAsNew: true))
                                                }
                                                dismissSheet()
                                            }, label: {
                                                HStack {
                                                    Image(uiImage: UIImage(contentsOfFile: Bundle.main.bundlePath + "/AvatorDiffs/\(choseSchoolName)/\(choseCharacterName)/\(images[i])")!)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 120)
                                                    Text("差分表情 #\(i + 1)")
                                                }
                                            })
                                        }
                                    }
                                }
                            }
                            .navigationTitle("选择差分表情")
                            .onAppear {
                                do {
                                    images = try FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath + "/AvatorDiffs/\(choseSchoolName)/\(choseCharacterName)")
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }
                }
            }
            struct SpecialEventAddTipView: View {
                @Binding var shouldAddSpecialEvent: Bool
                @Environment(\.dismiss) var dismiss
                @AppStorage("IsIgnoreSpecialEventTip") var isIgnoreSpecialEventTip = false
                var body: some View {
                    NavigationStack {
                        HStack {
                            Image(uiImage: UIImage(contentsOfFile: Bundle.main.path(forResource: "TipShiroko", ofType: "avif")!)!)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150)
                            VStack {
                                Text("老师，添加羁绊剧情可能影响观看体验\n一设如何？")
                                    .font(.system(size: 18))
                                    .multilineTextAlignment(.center)
                                Spacer()
                                    .frame(height: 20)
                                Button(action: {
                                    dismiss()
                                }, label: {
                                    HStack {
                                        Spacer()
                                        Text("不添加")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                })
                                .tint(.blue)
                                .buttonStyle(.borderedProminent)
                                .buttonBorderShape(.roundedRectangle(radius: 14))
                                .padding(.horizontal, 20)
                                Button(action: {
                                    shouldAddSpecialEvent = true
                                    dismiss()
                                }, label: {
                                    HStack {
                                        Spacer()
                                        Text("添加")
                                            .font(.system(size: 18, weight: .medium))
                                        Spacer()
                                    }
                                })
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.roundedRectangle(radius: 14))
                                .padding(.horizontal, 20)
                                Button(action: {
                                    isIgnoreSpecialEventTip = true
                                    shouldAddSpecialEvent = true
                                    dismiss()
                                }, label: {
                                    HStack {
                                        Spacer()
                                        Text("添加,\n 以后不再提醒")
                                            .font(.system(size: 18, weight: .medium))
                                            .multilineTextAlignment(.center)
                                        Spacer()
                                    }
                                })
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.roundedRectangle(radius: 14))
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding()
                        .navigationTitle("提示")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: {
                                    dismiss()
                                }, label: {
                                    Image(systemName: "xmark")
                                        .bold()
                                        .foregroundStyle(Color.gray)
                                })
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.circle)
                            }
                        }
                    }
                }
            }
        }
        
        struct ProjectSettingsView: View {
            var projName: String
            var dismissAction: DismissAction
            @Binding var fullProjData: MTBase.FullData?
            @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
            @Binding var currentSelectCharacterImageGroupIndex: Int
            @Environment(\.dismiss) var dismiss
            @AppStorage("IsAutoSave") var autoSave = true
            @State var isExportAsImagePresented = false
            @State var isExportAsVideoPresented = false
            @State var isShareSheetPresented = false
            @State var isEditRawTipped = false
            @State var isRawEditorPresented = false
            var body: some View {
                NavigationStack {
                    List {
                        Section(header: Text("导出")) {
                            Button(action: {
                                isExportAsImagePresented = true
                            }, label: {
                                Text("图片...")
                            })
                            .sheet(isPresented: $isExportAsImagePresented, onDismiss: {
                                dismiss()
                            }, content: { ExportAsImageView(projName: projName, fullProjData: $fullProjData, currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex) })
                            .disabled(fullProjData!.chatData.isEmpty)
                            Button(action: {
                                isExportAsVideoPresented = true
                            }, label: {
                                Text("视频...")
                            })
                            .sheet(isPresented: $isExportAsVideoPresented, onDismiss: {
                                dismiss()
                            }, content: { ExportAsVideoView(projName: projName, fullProjData: $fullProjData, currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex) })
                            .disabled(fullProjData!.chatData.isEmpty)
                            Button(action: {
                                let sourceURL = AppFileManager(path: "MTProj").GetPath(projName).url
                                let destinationUrl = FileManager.default.temporaryDirectory.appendingPathComponent(sourceURL.lastPathComponent)
                                do {
                                    if FileManager.default.fileExists(atPath: destinationUrl.path) {
                                        try FileManager.default.removeItem(at: destinationUrl)
                                    }
                                    try FileManager.default.copyItem(at: sourceURL, to: destinationUrl)
                                    isShareSheetPresented = true
                                } catch {
                                    print("Failed to copy file: \(error)")
                                }
                            }, label: {
                                Text("文件...")
                            })
                            .sheet(isPresented: $isShareSheetPresented, onDismiss: {
                                dismiss()
                            }, content: {ShareSheet(activityItems: [FileManager.default.temporaryDirectory.appendingPathComponent(AppFileManager(path: "MTProj").GetPath(projName).url.lastPathComponent)])})
                        }
                        
                        Section(header: Text("操作")) {
                            Toggle("自动保存项目", isOn: $autoSave)
                            Button(action: {
                                SaveProject()
                                mtIsHaveUnsavedChange = false
                                DarockKit.UIAlert.shared.presentAlert(title: "成功", subtitle: "项目已保存", icon: .done, style: .iOS17AppleMusic, haptic: .success)
                            }, label: {
                                Text("保存")
                            })
                            Button(action: {
                                SaveProject()
                                mtIsHaveUnsavedChange = false
                                dismissAction()
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
                                dismissAction()
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
                                dismissAction()
                            }
                        }
                        
                        Section(header: Text("高级")) {
                            Button(action: {
                                if isEditRawTipped {
                                    SaveProject()
                                    isRawEditorPresented = true
                                } else {
                                    DarockKit.UIAlert.shared.presentAlert(title: "注意", subtitle: "编辑源文件可能导致项目损坏\n仅适合高级用户\n再次单击以编辑", icon: .none, style: .iOS17AppleMusic, haptic: .warning, duration: 3)
                                    isEditRawTipped = true
                                }
                            }, label: {
                                Text("编辑源文件")
                            })
                            .fullScreenCover(isPresented: $isRawEditorPresented, onDismiss: {
                                let fullFileContent = try! String(contentsOfFile: AppFileManager(path: "MTProj").GetFilePath(name: projName).path)
                                fullProjData = MTBase().toFullData(byString: fullFileContent)
                            }, content: { MTRawEditorView(projName: projName) })
                        }
                    }
                    .navigationTitle("项目管理")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                dismiss()
                            }, label: {
                                Image(systemName: "xmark")
                                    .bold()
                                    .foregroundStyle(Color.gray)
                            })
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.circle)
                        }
                    }
                }
            }
            
            struct ImageShoterView: View {
                var projName: String
                @Binding var fullProjData: MTBase.FullData?
                @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
                @Binding var currentSelectCharacterImageGroupIndex: Int
                @Binding var splittingMethod: MTExporter.ImageExportSplittingMethod
                @Binding var isShottingAll: Bool
                @Binding var shottingImageCount: Int
                @Binding var finishHandler: (UIImage, Int) -> Void
                @State var isScreenShotting = [false]
                @State var splitByIndexInput = "5"
                @State var splittedChatDatas = [[MTBase.SingleChatData]]()
                var body: some View {
                    VStack {
                        HStack {
                            Button(action: {
                                splittingMethod = .none
                                shottingImageCount = 1
                            }, label: {
                                Text("不切割")
                            })
                            .tint(splittingMethod == .none ? .blue : .gray)
                            .buttonStyle(.bordered)
                            Button(action: {
                                splittedChatDatas = MTExporter.shared.splitChatData(in: fullProjData!.chatData, by: .byCharacter)
                                isScreenShotting = Array(repeating: false, count: splittedChatDatas.count)
                                splittingMethod = .byCharacter
                                shottingImageCount = splittedChatDatas.count
                            }, label: {
                                HStack {
                                    Text("按照角色切割")
                                }
                            })
                            .tint(splittingMethod == .byCharacter ? .blue : .gray)
                            .buttonStyle(.bordered)
                            Button(action: {
                                splittedChatDatas = MTExporter.shared.splitChatData(in: fullProjData!.chatData, by: .byIndex(5))
                                isScreenShotting = Array(repeating: false, count: splittedChatDatas.count)
                                splittingMethod = .byIndex(5)
                                shottingImageCount = splittedChatDatas.count
                            }, label: {
                                Text("按照消息数切割")
                            })
                            .tint({ if case .byIndex(_) = splittingMethod { return Color.blue } else { return Color.gray } }())
                            .buttonStyle(.bordered)
                        }
                        if case .byIndex(_) = splittingMethod {
                            HStack {
                                Text("每")
                                TextField("", text: $splitByIndexInput)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                                    .frame(width: 50)
                                    .onChange(of: splitByIndexInput) {
                                        if let intedInput = Int(splitByIndexInput) {
                                            splittedChatDatas = MTExporter.shared.splitChatData(in: fullProjData!.chatData, by: .byIndex(intedInput))
                                            isScreenShotting = Array(repeating: false, count: splittedChatDatas.count)
                                            splittingMethod = .byIndex(intedInput)
                                            shottingImageCount = splittedChatDatas.count
                                        }
                                    }
                                Text("条消息进行切割")
                            }
                            .padding(.horizontal)
                        }
                        Divider()
                        if splittingMethod == .none {
                            ScreenshotableView(shotting: $isScreenShotting[0]) { screenshot in
                                finishHandler(screenshot, 0)
                            } content: { style in
                                MainChatsView(projName: projName, fullProjData: $fullProjData, newMessageTextCache: .constant(""), currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex, isInserting: .constant(false))
                            }
                        } else {
                            if !splittedChatDatas.isEmpty {
                                ForEach(0..<splittedChatDatas.count, id: \.self) { i in
                                    VStack {
                                        Text("图片 #\(i + 1)")
                                        ScreenshotableView(shotting: $isScreenShotting[i]) { screenshot in
                                            finishHandler(screenshot, i)
                                        } content: { style in
                                            MainChatsView(projName: projName, fullProjData: $fullProjData, newMessageTextCache: .constant(""), currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex, isInserting: .constant(false), displayMessageIndexRange: { () -> ClosedRange<Int> in
                                                var rangeStart = 0
                                                for j in 0..<i {
                                                    rangeStart += splittedChatDatas[j].count
                                                }
                                                let rangeEnd = rangeStart + splittedChatDatas[i].count - 1
                                                return rangeStart...rangeEnd
                                            }())
                                        }
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    .onChange(of: isShottingAll) {
                        for i in 0..<isScreenShotting.count {
                            isScreenShotting[i].toggle()
                        }
                    }
                }
            }
            struct ExportAsImageView: View {
                var projName: String
                @Binding var fullProjData: MTBase.FullData?
                @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
                @Binding var currentSelectCharacterImageGroupIndex: Int
                @Environment(\.dismiss) var dismiss
                @State var splittingMethod = MTExporter.ImageExportSplittingMethod.none
                @State var isShotting = false
                @State var shottingCount = 1
                @State var currentFinishHandler: (UIImage, Int) -> Void = { _, _ in }
                var body: some View {
                    NavigationStack {
                        ScrollView {
                            VStack {
                                ImageShoterView(projName: projName, fullProjData: $fullProjData, currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex, splittingMethod: $splittingMethod, isShottingAll: $isShotting, shottingImageCount: $shottingCount, finishHandler: $currentFinishHandler)
                                Button(action: {
                                    if splittingMethod == .none {
                                        currentFinishHandler = { image, index in
                                            saveImageToPhotoLibrary(image: image)
                                            DarockKit.UIAlert.shared.presentAlert(title: "导出", subtitle: "已将图片导出到相册", icon: .done, style: .iOS17AppleMusic, haptic: .success)
                                        }
                                        isShotting.toggle()
                                    } else {
                                        let alert = AlertAppleMusic17View(title: "导出...", subtitle: "正在导出图片到相册...", icon: .spinnerSmall, duration: 2)
                                        let window = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first
                                        if let window = window {
                                            alert.present(on: window)
                                        }
                                        DispatchQueue(label: "com.Neinnko.BAGen.Project-Export.Image", qos: .userInitiated).async {
                                            let group = DispatchGroup()
                                            for _ in 0..<shottingCount {
                                                group.enter()
                                            }
                                            var finishedScreenshots = [(UIImage, Int)]()
                                            currentFinishHandler = { image, index in
                                                finishedScreenshots.append((image, index))
                                                group.leave()
                                            }
                                            group.notify(queue: .main) {
                                                finishedScreenshots.sort { lhs, rhs in lhs.1 < rhs.1 }
                                                for (image, _) in finishedScreenshots {
                                                    saveImageToPhotoLibrary(image: image)
                                                }
                                                alert.dismiss()
                                                DarockKit.UIAlert.shared.presentAlert(title: "导出", subtitle: "已将图片导出到相册", icon: .done, style: .iOS17AppleMusic, haptic: .success)
                                            }
                                            isShotting.toggle()
                                        }
                                    }
                                }, label: {
                                    HStack {
                                        Spacer()
                                        Text("导出到相册...")
                                        Spacer()
                                    }
                                    .padding(.vertical, 5)
                                })
                                .buttonStyle(.borderedProminent)
                                .padding()
                            }
                        }
                        .scrollDismissesKeyboard(.immediately)
                        .navigationTitle("导出为图片")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: {
                                    dismiss()
                                }, label: {
                                    Image(systemName: "xmark")
                                        .bold()
                                        .foregroundStyle(Color.gray)
                                })
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.circle)
                            }
                        }
                    }
                }
            }
            struct ExportAsVideoView: View {
                var projName: String
                @Binding var fullProjData: MTBase.FullData?
                @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
                @Binding var currentSelectCharacterImageGroupIndex: Int
                @Environment(\.dismiss) var dismiss
                @State var splittingMethod = MTExporter.ImageExportSplittingMethod.none
                @State var isShotting = false
                @State var isExporting = false
                @State var shottingCount = 1
                @State var currentFinishHandler: (UIImage, Int) -> Void = { _, _ in }
                @State var shotImages = [UIImage]()
                @State var singleImageDuration = 5.0
                @State var singleImageDurationInput = "5.0"
                @State var bgmName = ""
                var body: some View {
                    NavigationStack {
                        ScrollView {
                            VStack {
                                ImageShoterView(projName: projName, fullProjData: $fullProjData, currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex, splittingMethod: $splittingMethod, isShottingAll: $isShotting, shottingImageCount: $shottingCount, finishHandler: $currentFinishHandler)
                                List {
                                    Section {
                                        HStack {
                                            Text("单张图片持续时间")
                                            Spacer()
                                            TextField("时间", text: $singleImageDurationInput)
                                                .submitLabel(.done)
                                                .onSubmit {
                                                    if let dValue = Double(singleImageDurationInput) {
                                                        singleImageDuration = dValue
                                                    } else {
                                                        singleImageDurationInput = String(singleImageDuration)
                                                    }
                                                }
                                        }
                                        NavigationLink(destination: { BackgroundMusicChooseView(currentChoseName: $bgmName) }, label: {
                                            HStack {
                                                Text("背景音乐...")
                                                Spacer()
                                                Text(!bgmName.isEmpty ? bgmName : "无")
                                                    .lineLimit(1)
                                                    .foregroundStyle(Color.gray)
                                            }
                                        })
                                    } header: {
                                        Text("视频设置")
                                    }
                                }
                                .scrollDisabled(true)
                                .frame(height: 300)
                                Divider()
                                Button(action: {
                                    isExporting = true
                                    if splittingMethod == .none {
                                        currentFinishHandler = { image, index in
                                            saveImageToPhotoLibrary(image: image)
                                            DarockKit.UIAlert.shared.presentAlert(title: "导出", subtitle: "已将图片导出到相册", icon: .done, style: .iOS17AppleMusic, haptic: .success)
                                            isExporting = false
                                        }
                                        isShotting.toggle()
                                    } else {
                                        let alert = AlertAppleMusic17View(title: "导出...", subtitle: "正在导出视频...", icon: .spinnerSmall, duration: 2)
                                        let window = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first
                                        if let window = window {
                                            alert.present(on: window)
                                        }
                                        DispatchQueue(label: "com.Neinnko.BAGen.Project-Export.Video", qos: .userInitiated).async {
                                            let group = DispatchGroup()
                                            for _ in 0..<shottingCount {
                                                group.enter()
                                            }
                                            var finishedScreenshots = [(UIImage, Int)]()
                                            currentFinishHandler = { image, index in
                                                finishedScreenshots.append((image, index))
                                                group.leave()
                                            }
                                            group.notify(queue: .main) {
                                                finishedScreenshots.sort { lhs, rhs in lhs.1 < rhs.1 }
                                                shotImages.removeAll()
                                                for (image, _) in finishedScreenshots {
                                                    shotImages.append(image)
                                                }
                                                // MARK: Step 1 - Get All Screenshot, Finished here.
                                                
                                                let audioUrls: [URL]
                                                if !bgmName.isEmpty {
                                                    audioUrls = [Bundle.main.url(forResource: bgmName, withExtension: "mp3", subdirectory: "OSTAudio")!]
                                                } else {
                                                    audioUrls = []
                                                }
                                                VideoGenerator.fileName = "ExportVideo"
                                                VideoGenerator.shouldOptimiseImageForVideo = true
                                                VideoGenerator.scaleWidth = 1920
                                                VideoGenerator.videoDurationInSeconds = singleImageDuration
                                                VideoGenerator.maxVideoLengthInSeconds = singleImageDuration * Double(shotImages.count)
                                                VideoGenerator.current.generate(withImages: shotImages, andAudios: audioUrls, andType: .singleAudioMultipleImage, { progress in
                                                    debugPrint(progress)
                                                }, outcome: { result in
                                                    switch result {
                                                    case .success(let success):
                                                        saveVideoToPhotoLibrary(video: success)
                                                        alert.dismiss()
                                                        DarockKit.UIAlert.shared.presentAlert(title: "导出", subtitle: "已将视频导出到相册", icon: .done, style: .iOS17AppleMusic, haptic: .success)
                                                    case .failure(let error):
                                                        print(error)
                                                    }
                                                    isExporting = false
                                                })
                                            }
                                            isShotting.toggle()
                                        }
                                    }
                                }, label: {
                                    HStack {
                                        Spacer()
                                        Text("开始导出")
                                        Spacer()
                                    }
                                    .padding(.vertical, 5)
                                })
                                .buttonStyle(.borderedProminent)
                                .disabled(isExporting)
                                .padding()
                            }
                        }
                        .scrollDismissesKeyboard(.immediately)
                        .navigationTitle("导出为视频")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: {
                                    dismiss()
                                }, label: {
                                    Image(systemName: "xmark")
                                        .bold()
                                        .foregroundStyle(Color.gray)
                                })
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.circle)
                            }
                        }
                    }
                    .interactiveDismissDisabled()
                }
                
                struct BackgroundMusicChooseView: View {
                    @Binding var currentChoseName: String
                    @Environment(\.dismiss) var dismiss
                    @State var allMusicNames = [String]()
                    @State var searchText = ""
                    @State var audioPower1 = -160.0
                    @State var audioPower2 = -160.0
                    var body: some View {
                        List {
                            Section {
                                Button(action: {
                                    currentChoseName = ""
                                    globalAudioPlayer.stop()
                                }, label: {
                                    HStack {
                                        Text("无")
                                            .foregroundStyle(Color.black)
                                        Spacer()
                                        if currentChoseName.isEmpty {
                                            Image(systemName: "checkmark")
                                                .bold()
                                                .foregroundStyle(Color.blue)
                                        }
                                    }
                                })
                                if !allMusicNames.isEmpty {
                                    ForEach(0..<allMusicNames.count, id: \.self) { i in
                                        if searchText.isEmpty || allMusicNames[i].lowercased().contains(searchText.lowercased()) {
                                            Button(action: {
                                                currentChoseName = allMusicNames[i]
                                                do {
                                                    globalAudioPlayer = try AVAudioPlayer(contentsOf: Bundle.main.url(forResource: allMusicNames[i], withExtension: "mp3", subdirectory: "OSTAudio")!)
                                                    globalAudioPlayer.play()
                                                    globalAudioPlayer.isMeteringEnabled = true
                                                } catch {
                                                    print(error)
                                                }
                                            }, label: {
                                                HStack {
                                                    Text(allMusicNames[i])
                                                        .foregroundStyle(Color.black)
                                                    Spacer()
                                                    if currentChoseName == allMusicNames[i] {
//                                                        Image(systemName: "checkmark")
//                                                            .bold()
//                                                            .foregroundStyle(Color.blue)
                                                        HStack(spacing: 2) {
                                                            bar(5 + pow(((audioPower1 - 5 + 160) / 160), 20) * 25)
                                                            bar(5 + pow(((audioPower2 - 3 + 160) / 160), 20) * 25)
                                                            bar(5 + pow(((audioPower1 + 160) / 160), 20) * 25)
                                                            bar(5 + pow(((audioPower2 + 160) / 160), 20) * 25)
                                                            bar(5 + pow(((audioPower2 - 3 + 160) / 160), 20) * 25)
                                                            bar(5 + pow(((audioPower1 - 5 + 160) / 160), 20) * 25)
                                                        }
                                                        .frame(width: 30)
                                                        .animation(.smooth(duration: 0.1), value: audioPower1)
                                                        .animation(.smooth(duration: 0.1), value: audioPower2)
                                                    }
                                                }
                                            })
                                        }
                                    }
                                }
                            }
                        }
                        .searchable(text: $searchText)
                        .navigationTitle("选择背景音乐")
                        .onAppear {
                            do {
                                allMusicNames = try FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath + "/OSTAudio").map { String($0.split(separator: ".")[0]) }
                                allMusicNames.sort()
                            } catch {
                                print(error)
                            }
                            Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                                globalAudioPlayer.updateMeters()
                                audioPower1 = Double(globalAudioPlayer.averagePower(forChannel: 0))
                                audioPower2 = Double(globalAudioPlayer.averagePower(forChannel: 1))
                            }
                        }
                        .onDisappear {
                            globalAudioPlayer.stop()
                        }
                    }
                    
                    func bar(_ height: CGFloat) -> some View {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: 0xe3e3e1))
                            .frame(height: height)
                    }
                }
            }
            
            func SaveProject() {
                let projStrData = MTBase().toOutString(from: fullProjData!)
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
        var shouldShowAsNew: Bool
    }
    struct SingleCharacterData: Identifiable, Equatable, Codable {
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
                continue
            }
            if let imgGroupIndex = Int(dataSpd[1]),
               let isshouldShowAsNew = Bool(dataSpd[3]) {
                let isImage = dataSpd[2].hasPrefix("%%TImage%%*")
                tmpChatData.append(SingleChatData(characterId: dataSpd[0], imageGroupIndex: imgGroupIndex, isImage: isImage, content: isImage ? String(dataSpd[2].dropFirst(11)) : dataSpd[2], shouldShowAsNew: isshouldShowAsNew))
            }
        }
        return FullData(chatData: tmpChatData)
    }
    func toOutString(from inp: FullData) -> String {
        let chatData = inp.chatData
        var tmpOutStr = ""
        for singleChat in chatData {
            tmpOutStr += "\(singleChat.characterId)|\(singleChat.imageGroupIndex)|\(singleChat.isImage ? "%%TImage%%*" : "")\(singleChat.content)|\(singleChat.shouldShowAsNew)\n"
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
            tmpOutDatas.append(SingleCharacterData(id: character.1["id"].string!, fullName: character.1["names"]["zh-cn"].string! == "" ? character.1["names"]["ja"].string! : character.1["names"]["zh-cn"].string!, shortName: character.1["short_names"]["zh-cn"].string! == "" ? character.1["short_names"]["ja"].string! : character.1["short_names"]["zh-cn"].string!, imageNames: character.1["images"].arrayObject! as! [String]))
        }
        return tmpOutDatas
    }
}

func base64ToImage(from inp: String) -> UIImage? {
    if let dataDecoded = Data(base64Encoded: inp, options: NSData.Base64DecodingOptions(rawValue: 0)) {
        let decodedimage = UIImage(data: dataDecoded)
        return decodedimage
    }
    return nil
}
