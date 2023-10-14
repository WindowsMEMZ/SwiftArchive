//
//  MTEditorView.swift
//  BAGen
//
//  Created by memz233 on 2023/10/5.
//

import SwiftUI
import DarockKit
import SwiftyJSON
import ScreenshotableView

// 文件格式:
// 文本对话: {角色 ID(String)}|{头像组下标(Int)}|{内容}|{ShowldShowAsNew(Bool)}
// 图片:    {角色 ID(String)}|{头像组下标(Int)}|"%%TImage%%*"(图像标记){图像 Base64}|{ShowldShowAsNew(Bool)}
// 按行分隔
// 角色 ID 为 "Sensei" 时显示消息由我方发出
// 角色 ID 为 "SpecialEvent" 使显示羁绊剧情, 此时内容为羁绊剧情对象
// 角色 ID 为 "System" 时显示系统信息

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
                        MainChatsView(fullProjData: $fullProjData, newMessageTextCache: $newMessageTextCache, currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex, isInserting: $isInserting)
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
                                mtIsHaveUnsavedChange = true
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
                        
                    }, content: {ChatActionsView(characterSelectTab: $characterSelectTab, currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex, fullProjData: $fullProjData, projName: projName)})
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
            
            mtIsHaveUnsavedChange = false
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
    
    struct MainChatsView: View {
        @Binding var fullProjData: MTBase.FullData?
        @Binding var newMessageTextCache: String
        @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
        @Binding var currentSelectCharacterImageGroupIndex: Int
        @Binding var isInserting: Bool
        var displayMessageIndexRange: ClosedRange<Int>? = nil // For ScreenShot
        var body: some View {
            VStack {
                ForEach(0..<fullProjData!.chatData.count, id: \.self) { i in
                    if displayMessageIndexRange == nil || (displayMessageIndexRange ?? 0...1).contains(i) {
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
                        } else if fullProjData!.chatData[i].characterId == "SpecialEvent" {
                            // MARK: Special Event Message View
                            // TODO: Display, Delete, Insert Support
                            HStack {
                                Spacer()
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(hex: 0xFCEBF0))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color(hex: 0xCDCDCD), lineWidth: 1)
                                        }
                                        .frame(width: 180, height: 60)
                                    HStack {
                                        Spacer()
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(Color(hex: 0xFFCBD6))
                                            .offset(x: 20)
                                    }
                                }
                                .frame(width: 180, height: 60)
                                Spacer()
                                    .frame(width: 10)
                            }
                        } else if fullProjData!.chatData[i].characterId == "System" {
                            // MARK: Message View from System
                            HStack {
                                Spacer()
                                BAText(fullProjData!.chatData[i].content, fontSize: 16, textColor: Color(hex: 0x3C454F), isSystemd: true)
                                Spacer()
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
                        } else {
                            // MARK: Other Character Message View
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
                                    // Character Name
                                    if fullProjData!.chatData[i].showldShowAsNew {
                                        HStack {
                                            BAText(thisCharacterData.shortName, fontSize: 16, isSystemd: true)
                                                .padding(0)
                                                .offset(x: 3, y: 5)
                                            Spacer()
                                        }
                                    }
                                    HStack(alignment: .top) {
                                        // Message Bubble
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
                                            // Text Content
                                            BAText(fullProjData!.chatData[i].content, fontSize: 18, textColor: .white, isSystemd: true, isBold: false)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .padding(10)
                                                .background {
                                                    RoundedRectangle(cornerRadius: 7)
                                                        .fill(Color(hex: 0x435165))
                                                }
                                        } else {
                                            
                                        }
                                        Spacer()
                                    }
                                    .offset(x: -10)
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
                        }
                    }
                }
            }
            .background(Color(hex: 0xFFF6DD))
        }
    }
    
    struct ChatActionsView: View {
        @Binding var characterSelectTab: [[String: Any]]?
        @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
        @Binding var currentSelectCharacterImageGroupIndex: Int
        @Binding var fullProjData: MTBase.FullData?
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
                SendSpecialMessageView(currentSelectCharacterData: $currentSelectCharacterData, fullProjData: $fullProjData)
                    .tag(2)
                    .tabItem {
                        Label("特殊消息", systemImage: "star.bubble")
                            .symbolRenderingMode(.hierarchical)
                    }
                ProjectSettingsView(projName: projName, fullProjData: $fullProjData, currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex)
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
            @State var searchText = ""
            @State var searchedCharacterDatas: [MTBase.SingleCharacterData]? = nil
            var body: some View {
                NavigationView {
                    List {
                        if allCharacterDatas != nil {
                            if searchText == "" || searchedCharacterDatas == nil || searchedCharacterDatas?.count == 0 {
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
                            } else {
                                ForEach(0..<searchedCharacterDatas!.count, id: \.self) { i in
                                    NavigationLink(destination: {AddCharacterSettingView(selectedCharacterData: searchedCharacterDatas![i], characterSelectTab: $characterSelectTab, nowTabviewSelection: $nowTabviewSelection)}, label: {
                                        HStack {
                                            Image(uiImage: UIImage(data: try! Data(contentsOf: Bundle.main.url(forResource: searchedCharacterDatas![i].imageNames[0], withExtension: "png")!))!)
                                                .resizable()
                                                .frame(width: 50, height: 50)
                                                .clipShape(Circle())
                                            Spacer()
                                            Text(searchedCharacterDatas![i].fullName)
                                        }
                                    })
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "搜索...")
                    .onChange(of: searchText) { value in
                        searchedCharacterDatas = [MTBase.SingleCharacterData]()
                        for i in 0..<allCharacterDatas!.count {
                            if allCharacterDatas![i].fullName.contains(searchText) {
                                searchedCharacterDatas!.append(allCharacterDatas![i])
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
        
        struct SendSpecialMessageView: View {
            @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
            @Binding var fullProjData: MTBase.FullData?
            @Environment(\.dismiss) var dismiss
            @AppStorage("IsIgnoreSpecialEventTip") var isIgnoreSpecialEventTip = false
            @State var systemMessageInputCache = ""
            @State var shouldAddSpecialEvent = false
            @State var isSpecialEventAddTipPresented = false
            var body: some View {
                NavigationView {
                    List {
                        TextField("系统消息", text: $systemMessageInputCache)
                            .onSubmit {
                                fullProjData!.chatData.append(.init(characterId: "System", imageGroupIndex: 0, isImage: false, content: systemMessageInputCache, showldShowAsNew: true))
                                systemMessageInputCache = ""
                                dismiss()
                            }
                        Button(action: {
                            if !isIgnoreSpecialEventTip {
                                isSpecialEventAddTipPresented = true
                            } else {
                                AddNewSpecialEvent()
                                dismiss()
                            }
                        }, label: {
                            Text("羁绊剧情")
                        })
                        .sheet(isPresented: $isSpecialEventAddTipPresented, onDismiss: {
                            if shouldAddSpecialEvent {
                                shouldAddSpecialEvent = false
                                AddNewSpecialEvent()
                                dismiss()
                            }
                        }, content: {SpecialEventAddTipView(shouldAddSpecialEvent: $shouldAddSpecialEvent)})
                    }
                    .navigationTitle("特殊消息")
                }
            }
            
            func AddNewSpecialEvent() {
                fullProjData!.chatData.append(.init(characterId: "SpecialEvent", imageGroupIndex: 0, isImage: false, content: currentSelectCharacterData.shortName, showldShowAsNew: true))
            }
            
            struct SpecialEventAddTipView: View {
                @Binding var shouldAddSpecialEvent: Bool
                @Environment(\.dismiss) var dismiss
                @AppStorage("IsIgnoreSpecialEventTip") var isIgnoreSpecialEventTip = false
                var body: some View {
                    VStack {
                        Text("来自开发者的提示")
                            .font(.system(size: 22, weight: .bold))
                        Text("请慎用羁绊剧情\n添加羁绊剧情可能影响观看体验")
                            .font(.system(size: 18))
                        Spacer()
                            .frame(height: 20)
                        Button(action: {
                            dismiss()
                        }, label: {
                            Text("不添加")
                                .font(.system(size: 18, weight: .medium))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        })
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.blue)
                        .cornerRadius(14)
                        .foregroundColor(.white)
                        .padding(.horizontal, 25)
                        Button(action: {
                            shouldAddSpecialEvent = true
                            dismiss()
                        }, label: {
                            Text("添加")
                                .font(.system(size: 18, weight: .medium))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        })
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.gray)
                        .cornerRadius(14)
                        .foregroundColor(.black)
                        .padding(.horizontal, 25)
                        Button(action: {
                            isIgnoreSpecialEventTip = true
                            shouldAddSpecialEvent = true
                            dismiss()
                        }, label: {
                            Text("添加, 以后不再提醒")
                                .font(.system(size: 18, weight: .medium))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        })
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.gray)
                        .cornerRadius(14)
                        .foregroundColor(.black)
                        .padding(.horizontal, 25)
                    }
                }
            }
        }
        
        struct ProjectSettingsView: View {
            var projName: String
            @Binding var fullProjData: MTBase.FullData?
            @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
            @Binding var currentSelectCharacterImageGroupIndex: Int
            @Environment(\.dismiss) var dismiss
            @State var isExportAsImagePresented = false
            @State var isShareSheetPresented = false
            @State var isEditRawTipped = false
            @State var isRawEditorPresented = false
            var body: some View {
                NavigationView {
                    List {
                        Section(header: Text("导出")) {
                            Button(action: {
                                isExportAsImagePresented = true
                            }, label: {
                                Text("图片...")
                            })
                            .sheet(isPresented: $isExportAsImagePresented, onDismiss: {
                                dismiss()
                            }, content: {ExportAsImageView(fullProjData: $fullProjData, currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex)})
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
                        
                        Section(header: Text("高级")) {
                            Button(action: {
                                if isEditRawTipped {
                                    isRawEditorPresented = true
                                } else {
                                    DarockKit.UIAlert.shared.presentAlert(title: "注意", subtitle: "编辑源文件可能导致项目损坏\n仅适合高级用户\n再次单击以编辑", icon: .none, style: .iOS17AppleMusic, haptic: .warning, duration: 3)
                                    isEditRawTipped = true
                                }
                            }, label: {
                                Text("编辑源文件")
                            })
                            .fullScreenCover(isPresented: $isRawEditorPresented, onDismiss: {
                                
                            }, content: {MTRawEditorView(projName: projName)})
                        }
                    }
                    .navigationTitle("项目管理")
                }
            }
            
            struct ExportAsImageView: View {
                @Binding var fullProjData: MTBase.FullData?
                @Binding var currentSelectCharacterData: MTBase.SingleCharacterData
                @Binding var currentSelectCharacterImageGroupIndex: Int
                @State var isScreenShotting = [false]
                @State var splittingMethod = ImageExportSplittingMethod.none
                @State var splitByIndexInput = "5"
                @State var splittingIndexInterval = 5
                @State var chatDatasSplittedByCharacter = [[MTBase.SingleChatData]]()
                @State var chatDatasSplittedByIndex = [[MTBase.SingleChatData]]()
                @State var exportingImage = UIImage()
                @State var screenShotFinishHander: (() -> Void)? = nil
                var body: some View {
                    NavigationView {
                        List {
                            Section(header: Text("图片切割模式")) {
                                Button(action: {
                                    splittingMethod = .none
                                }, label: {
                                    HStack {
                                        if splittingMethod == .none {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                        Text("不切割")
                                    }
                                })
                                Button(action: {
                                    isScreenShotting.removeAll()
                                    for _ in chatDatasSplittedByCharacter {
                                        isScreenShotting.append(false)
                                    }
                                    splittingMethod = .byCharacter
                                }, label: {
                                    HStack {
                                        if splittingMethod == .byCharacter {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                        Text("按照角色切割")
                                    }
                                })
                                Button(action: {
                                    splittingMethod = .byIndex
                                    // Prepare Splited by Index Chat Datas
                                    let fullChatDatas = fullProjData!.chatData
                                    var addedCount = 0
                                    var tmpChatDataSplitting = [MTBase.SingleChatData]()
                                    for chatData in fullChatDatas {
                                        if addedCount == splittingIndexInterval {
                                            chatDatasSplittedByIndex.append(tmpChatDataSplitting)
                                            tmpChatDataSplitting.removeAll()
                                            addedCount = 0
                                        }
                                        tmpChatDataSplitting.append(chatData)
                                        addedCount += 1
                                    }
                                    isScreenShotting.removeAll()
                                    for _ in chatDatasSplittedByIndex {
                                        isScreenShotting.append(false)
                                    }
                                }, label: {
                                    HStack {
                                        if splittingMethod == .byIndex {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                        Text("按照消息数切割")
                                    }
                                })
                                if splittingMethod == .byIndex {
                                    HStack {
                                        Text("每")
                                        TextField("", text: $splitByIndexInput)
                                            .keyboardType(.numberPad)
                                            .onChange(of: splitByIndexInput) { _ in
                                                if let intedInput = Int(splitByIndexInput) {
                                                    splittingIndexInterval = intedInput
                                                    // Prepare Splited by Index Chat Datas
                                                    let fullChatDatas = fullProjData!.chatData
                                                    var addedCount = 0
                                                    var tmpChatDataSplitting = [MTBase.SingleChatData]()
                                                    for chatData in fullChatDatas {
                                                        if addedCount == splittingIndexInterval {
                                                            chatDatasSplittedByIndex.append(tmpChatDataSplitting)
                                                            tmpChatDataSplitting.removeAll()
                                                            addedCount = 0
                                                        }
                                                        tmpChatDataSplitting.append(chatData)
                                                        addedCount += 1
                                                    }
                                                    isScreenShotting.removeAll()
                                                    for _ in chatDatasSplittedByIndex {
                                                        isScreenShotting.append(false)
                                                    }
                                                }
                                            }
                                        Text("条消息进行切割")
                                    }
                                }
                            }
                            Section(header: Text("预览")) {
                                VStack {
                                    if splittingMethod == .none {
                                        ScreenshotableView(shotting: $isScreenShotting[0]) { screenshot in
                                            exportingImage = screenshot
                                            screenShotFinishHander!()
                                        } content: { style in
                                            MainChatsView(fullProjData: $fullProjData, newMessageTextCache: .constant(""), currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex, isInserting: .constant(false))
                                        }
                                    } else if splittingMethod == .byCharacter {
                                        if chatDatasSplittedByCharacter.count != 0 {
                                            ForEach(0..<chatDatasSplittedByCharacter.count, id: \.self) { i in
                                                VStack {
                                                    Text("图片 #\(i + 1)")
                                                    ScreenshotableView(shotting: $isScreenShotting[i]) { screenshot in
                                                        exportingImage = screenshot
                                                        debugPrint("ScreenShot \(i)")
                                                        screenShotFinishHander!()
                                                    } content: { style in
                                                        MainChatsView(fullProjData: $fullProjData, newMessageTextCache: .constant(""), currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex, isInserting: .constant(false), displayMessageIndexRange: { () -> ClosedRange<Int> in
                                                            var rangeStart = 0
                                                            for j in 0..<i {
                                                                rangeStart += chatDatasSplittedByCharacter[j].count
                                                            }
                                                            let rangeEnd = rangeStart + chatDatasSplittedByCharacter[i].count - 1
                                                            return rangeStart...rangeEnd
                                                        }())
                                                    }
                                                    Divider()
                                                }
                                            }
                                        }
                                    } else if splittingMethod == .byIndex {
                                        if chatDatasSplittedByIndex.count != 0 {
                                            ForEach(0..<chatDatasSplittedByIndex.count, id: \.self) { i in
                                                VStack {
                                                    Text("图片 #\(i + 1)")
                                                    ScreenshotableView(shotting: $isScreenShotting[i]) { screenshot in
                                                        exportingImage = screenshot
                                                        screenShotFinishHander!()
                                                    } content: { style in
                                                        MainChatsView(fullProjData: $fullProjData, newMessageTextCache: .constant(""), currentSelectCharacterData: $currentSelectCharacterData, currentSelectCharacterImageGroupIndex: $currentSelectCharacterImageGroupIndex, isInserting: .constant(false), displayMessageIndexRange: { () -> ClosedRange<Int> in
                                                            var rangeStart = 0
                                                            for j in 0..<i {
                                                                rangeStart += chatDatasSplittedByIndex[j].count
                                                            }
                                                            let rangeEnd = rangeStart + chatDatasSplittedByIndex[i].count - 1
                                                            return rangeStart...rangeEnd
                                                        }())
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            Section(header: Text("完成导出")) {
                                Button(action: {
                                    if splittingMethod == .none {
                                        screenShotFinishHander = {
                                            saveImageToPhotoLibrary(image: exportingImage)
                                            DarockKit.UIAlert.shared.presentAlert(title: "导出", subtitle: "已将图片导出到相册", icon: .done, style: .iOS17AppleMusic, haptic: .success)
                                        }
                                        isScreenShotting[0] = true
                                    } else {
                                        // FIXME: Some Images were Splitted
                                        let alert = AlertAppleMusic17View(title: "导出...", subtitle: "正在导出图片到相册...", icon: .spinnerSmall, duration: 2)
                                        alert.haptic = .warning
                                        let window = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first
                                        if let window = window {
                                            alert.present(on: window)
                                        }
                                        for i in 0..<isScreenShotting.count {
                                            if i != isScreenShotting.count - 1 {
                                                screenShotFinishHander = {
                                                    saveImageToPhotoLibrary(image: exportingImage)
                                                }
                                            } else {
                                                screenShotFinishHander = {
                                                    saveImageToPhotoLibrary(image: exportingImage)
                                                    alert.dismiss()
                                                    DarockKit.UIAlert.shared.presentAlert(title: "导出", subtitle: "已将图片导出到相册", icon: .done, style: .iOS17AppleMusic, haptic: .success)
                                                }
                                            }
                                            isScreenShotting[i].toggle()
                                        }
                                    }
                                }, label: {
                                    Text("导出到相册...")
                                })
                            }
                        }
                        .navigationTitle("导出为图片")
                    }
                    .onAppear {
                        // Prepare Splited by Chatacter Chat Datas
                        let fullChatDatas = fullProjData!.chatData
                        var tmpChatDataSplitting = [MTBase.SingleChatData]()
                        for chatData in fullChatDatas {
                            if let cdl = tmpChatDataSplitting.last {
                                if chatData.characterId == cdl.characterId {
                                    tmpChatDataSplitting.append(chatData)
                                } else {
                                    chatDatasSplittedByCharacter.append(tmpChatDataSplitting)
                                    tmpChatDataSplitting.removeAll()
                                    tmpChatDataSplitting.append(chatData)
                                }
                            } else {
                                tmpChatDataSplitting.append(chatData)
                            }
                        }
                    }
                }
                
                enum ImageExportSplittingMethod {
                    case none
                    case byCharacter
                    case byIndex
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
