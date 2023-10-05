//
//  FSEditorView.swift
//  BAGen
//
//  Created by WindowsMEMZ on 2023/10/2.
//

import AVKit
import SwiftUI

// 文件格式:
// !: 分隔每页
// +: 背景图片
// -: 背景音乐
// @: 角色名
// #: 角色所属
// $: 当前对话内容
// %: 角色动作(enum CharacterEmote(Int))
// ^: 角色表情(enum CharacterExpression(Int))
// &: 角色心理(enum CharacterSymbol(Int))
// *: 角色位置(Int 0...5(0 时不显示))
// ~: 角色定义开始
// `: 角色定义结束
// √: 分隔角色
// =: 选项开始和结束 选项在两个“=”内,按行分隔
// Example:
// +black.png
// -SAKURA PUNCH.mp3
// ~
// @Shiroko
// #对策委员会
// $与你的日常,就是奇迹
// %-1
// ^0
// &-1
// *2
// √
// @Shiroko
// #对策委员会
// $与你的日常,就是奇迹
// %-1
// ^0
// &0
// *4
// `
// =
// Choice1
// Choice2
// =
// !
// (AnotherPage)

struct FSEditorView: View {
    var projName: String = fsEnterProjName
    @Environment(\.colorScheme) var colorScheme
    @State var isFirstLoaded = false
    @State var fullFileContent = ""
    @State var fullProjData: FSBase.FullPageData? = nil
    @State var currentPage = 0
    @State var currentCharacterStep = 0
    @State var bgAudioPlayer: AVAudioPlayer?
    @State var isShowingMenu = false
    // MainMenu
    @State var isBgPathFileChooserPresented = false
    @State var bgPathFileChooserReturnPathCache = ""
    @State var isBgMusicPathFileChooserPresented = false
    @State var bgMusicPathFileChooserReturnPathCache = ""
    @State var isAddCharacterPresented = false
    /// Add Character
    ///
    var body: some View {
        ZStack {
            if fullProjData != nil {
                // BackgroundImage
                if fullProjData!.pages[currentPage].bgImagePath != nil {
                    Image(uiImage: UIImage(data: try! Data(contentsOf: URL(fileURLWithPath: fullProjData!.pages[currentPage].bgImagePath!)))!)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                } else {
                    Rectangle()
                        .fill(Color.black)
                        .ignoresSafeArea()
                }
                Group {
                    if fullProjData!.pages[currentPage].characters != nil {
                        // ContentLayer
                        VStack {
                            Spacer()
                                .frame(height: UIScreen.main.bounds.height - 120)
                            ZStack {
                                Rectangle()
                                    .fill(LinearGradient(colors: [Color.black.opacity(0.85), Color.black.opacity(0.1)], startPoint: .bottom, endPoint: .top))
                                    .frame(width: UIScreen.main.bounds.width, height: 150)
                                VStack {
                                    HStack {
                                        BAText(fullProjData!.pages[currentPage].characters![currentCharacterStep].name, fontSize: 26, textColor: .white, isSystemd: true)
                                        if fullProjData!.pages[currentPage].characters![currentCharacterStep].from != nil {
                                            Spacer()
                                                .frame(width: 15)
                                            BAText(fullProjData!.pages[currentPage].characters![currentCharacterStep].from!, fontSize: 20, textColor: .white, isSystemd: true)
                                                .offset(y: 5)
                                        }
                                        Spacer()
                                    }
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.black.opacity(0.1))
                                        .frame(height: 2)
                                    HStack {
                                        BAText(fullProjData!.pages[currentPage].characters![currentCharacterStep].content, fontSize: 20, textColor: .white, isSystemd: true)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    }
                    HStack {
                        Spacer()
                        VStack {
                            BAButton(action: {
                                isShowingMenu.toggle()
                            }, label: "MENU", isSmallStyle: true)
                            Spacer()
                        }
                        if isShowingMenu {
                            // MainMenu
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.4))
                                    .frame(width: 300)
                                ScrollView {
                                    VStack {
                                        Text("编辑菜单")
                                            .font(.system(size: 22, weight: .bold))
                                        HStack {
                                            VStack {
                                                Text("当前:")
                                                Text("第\(currentPage)页")
                                                    .offset(x: 20)
                                                Spacer()
                                                    .frame(height: 10)
                                                Text("全局")
                                                    .font(.system(size: 20, weight: .bold))
                                            }
                                            Spacer()
                                        }
                                        HStack {
                                            Text("背景图片:")
                                            Button(action: {
                                                isBgPathFileChooserPresented = true
                                            }, label: {
                                                Text((fullProjData!.pages[currentPage].bgImagePath ?? "选择").split(separator: "/").last ?? "选择")
                                                    .bold()
                                                    .foregroundColor(.blue)
                                            })
                                            .sheet(isPresented: $isBgPathFileChooserPresented, onDismiss: {
                                                if bgPathFileChooserReturnPathCache != "" {
                                                    fullProjData!.pages[currentPage].bgImagePath = bgPathFileChooserReturnPathCache
                                                    bgPathFileChooserReturnPathCache = ""
                                                }
                                            }, content: {PathFileChooserView(path: "res/defaultlocalgroup_assets_uis/03_scenario/01_background/Texture2D", previewType: .image, returnPath: $bgPathFileChooserReturnPathCache)})
                                        }
                                        HStack {
                                            Text("背景音乐:")
                                            Button(action: {
                                                isBgMusicPathFileChooserPresented = true
                                            }, label: {
                                                Text((fullProjData!.pages[currentPage].bgMusicPath ?? "选择").split(separator: "/").last ?? "选择")
                                                    .bold()
                                                    .foregroundColor(.blue)
                                            })
                                            .sheet(isPresented: $isBgMusicPathFileChooserPresented, onDismiss: {
                                                if bgMusicPathFileChooserReturnPathCache != "" {
                                                    fullProjData!.pages[currentPage].bgMusicPath = bgMusicPathFileChooserReturnPathCache
                                                    bgMusicPathFileChooserReturnPathCache = ""
                                                    if fullProjData!.pages[currentPage].bgMusicPath != nil {
                                                        bgAudioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: fullProjData!.pages[currentPage].bgMusicPath!))
                                                        bgAudioPlayer?.numberOfLoops = -1
                                                        bgAudioPlayer?.play()
                                                    }
                                                }
                                            }, content: {PathFileChooserView(path: "res/defaultlocalgroup_assets_audio/bgm", previewType: .music, returnPath: $bgMusicPathFileChooserReturnPathCache)})
                                        }
                                        HStack {
                                            VStack {
                                                Spacer()
                                                    .frame(height: 10)
                                                Text("人物")
                                                    .font(.system(size: 20, weight: .bold))
                                            }
                                            Spacer()
                                        }
                                        if fullProjData!.pages[currentPage].characters != nil && fullProjData!.pages[currentPage].characters?.count != 0 {
                                            
                                        } else {
                                            Button(action: {
                                                isAddCharacterPresented = true
                                            }, label: {
                                                Text("添加角色")
                                                    .bold()
                                                    .foregroundColor(.blue)
                                            })
                                            .sheet(isPresented: $isAddCharacterPresented, onDismiss: {
                                                
                                            }, content: {
                                                VStack {
                                                    Text("添加角色")
                                                        .font(.system(size: 24, weight: .bold))
                                                    Text("初始化")
                                                        .font(.system(size: 20, weight: .bold))
                                                    
                                                }
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            })
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(width: 300)
                                    .padding(.vertical, 10)
                                }
                            }
                        }
                    }
                    
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 10)
            } else {
                Text("Loading...")
            }
            
            //.ignoresSafeArea()
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .onAppear {
            if !isFirstLoaded {
                fullFileContent = try! String(contentsOfFile: AppFileManager(path: "FSProj").GetFilePath(name: projName).path)
                fullProjData = FSBase().ToFullData(byString: fullFileContent)
                if fullProjData?.pages.count != 0 {
                    if let bgMusicPath = fullProjData!.pages[currentPage].bgMusicPath {
                        debugPrint(bgMusicPath)
                        bgAudioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: bgMusicPath))
                        bgAudioPlayer?.numberOfLoops = -1
                        bgAudioPlayer?.play()
                    }
                }
                isFirstLoaded = true
            }
        }
    }
}

//MARK: FSClass
class FSBase {
    enum CharacterEmote: Int {
        case down = 0
        case leftFall = 1
        case rightFall = 2
        case doubleUp = 3
        case up = 4
        case shake = 5
        case largeShake = 6
    }
    enum CharacterSymbol: Int {
        case angry = 0
        case bulb = 1
        case speak = 2
        case dot = 3
        case exclaim = 4
        case suki = 5
        case ring = 6
        case question = 7
        case respond = 8
        case sad = 9
        case shy = 10
        case sigh = 11
        case steam = 12
        case surprise = 13
        case sweat = 14
        case tear = 15
        case think = 16
        case twinkle = 17
        case upset = 18
        case sleep = 19
    }
    
    struct FullPageData {
        var pages: [SinglePageData]
        var choices: [[String]?]
    }
    struct SinglePageData {
        var bgImagePath: String?
        var bgMusicPath: String?
        var characters: [CharacterData]?
    }
    struct CharacterData: Identifiable {
        var id: UUID = UUID()
        
        var name: String
        var from: String?
        var content: String
        var expression: Int
        var emote: CharacterEmote?
        var symbol: CharacterSymbol?
        var position: Int
    }
    
    private let resFolderName = "res"
    
    func ToFullData(byString inp: String) -> FullPageData {
        let paged = inp.split(separator: "!").map { String($0) } // 按页分割
        var tmpOutData = [SinglePageData]()
        var tmpChoicesOut = [[String]?]()
        for fullPageData in paged {
            let lined = fullPageData.split(separator: "\n").map { String($0) } // 按行分割
            var bgImagePath: String? = nil
            var bgMusicPath: String? = nil
            for singleLineData in lined {
                if singleLineData.hasPrefix("+") && singleLineData.count > 1 {
                    let bgImageResRootPath = AppFileManager(path: resFolderName).GetPath("defaultlocalgroup_assets_uis/03_scenario/01_background/Texture2D")
                    bgImagePath = bgImageResRootPath.string + String(singleLineData.dropFirst())
                } else if singleLineData.hasPrefix("-") && singleLineData.count > 1 {
                    let bgMusicResRootPath = AppFileManager(path: resFolderName).GetPath("defaultlocalgroup_assets_audio/bgm")
                    bgMusicPath = bgMusicResRootPath.string + String(singleLineData.dropFirst())
                }
            }
            // 角色变量
            var characterOutData: [CharacterData]? = nil
            if fullPageData.contains("~") && fullPageData.contains("`") {
                // 角色处理
                let characterDataStr = String(fullPageData.split(separator: "~")[1].split(separator: "`")[0])
                let singleCharacterDatas = characterDataStr.split(separator: "√").map { String($0) }
                for singleCharacterData in singleCharacterDatas {
                    let linedCharacterDatas = singleCharacterData.split(separator: "\n").map { String($0) }
                    // 变量
                    var name = "None"
                    var from: String? = nil
                    var content = "None"
                    var emote: CharacterEmote? = nil
                    var expression = 0
                    var symbol: CharacterSymbol? = nil
                    var position = 3
                    for linedCharacterData in linedCharacterDatas {
                        if linedCharacterData.hasPrefix("@") {
                            name = String(linedCharacterData.dropFirst())
                        } else if linedCharacterData.hasPrefix("#") {
                            from = String(linedCharacterData.dropFirst())
                        } else if linedCharacterData.hasPrefix("$") {
                            content = String(linedCharacterData.dropFirst())
                        } else if linedCharacterData.hasPrefix("%") {
                            if let rawData = Int(linedCharacterData.dropFirst()) {
                                if rawData != -1 {
                                    emote = .init(rawValue: rawData)
                                }
                            }
                        } else if linedCharacterData.hasPrefix("^") {
                            if let intData = Int(linedCharacterData.dropFirst()) {
                                expression = intData
                            }
                        } else if linedCharacterData.hasPrefix("&") {
                            if let rawData = Int(linedCharacterData.dropFirst()) {
                                if rawData != -1 {
                                    symbol = .init(rawValue: rawData)
                                }
                            }
                        } else if linedCharacterData.hasPrefix("*") {
                            if let intData = Int(linedCharacterData.dropFirst()) {
                                if (0...5).contains(intData) {
                                    position = intData
                                }
                            }
                        }
                    }
                    if characterOutData == nil {
                        characterOutData = [CharacterData]()
                    }
                    characterOutData?.append(CharacterData(name: name, from: from, content: content, expression: expression, emote: emote, symbol: symbol, position: position))
                }
            }
            tmpOutData.append(SinglePageData(bgImagePath: bgImagePath, bgMusicPath: bgMusicPath, characters: characterOutData))
            if fullPageData.hasSuffix("=") {
                let choicesStr = String(fullPageData.split(separator: "=")[1])
                let linedChoices = choicesStr.split(separator: "\n").map { String($0) }
                tmpChoicesOut.append(linedChoices)
            } else {
                tmpChoicesOut.append(nil)
            }
        }
        return FullPageData(pages: tmpOutData, choices: tmpChoicesOut)
    }
    func ToOutString(from inp: FullPageData) -> String {
        var tmpOutStr = ""
        let singlePageDatas = inp.pages
        let choiceDatas = inp.choices
        for i in 0..<singlePageDatas.count {
            if let bgImagePath = singlePageDatas[i].bgImagePath {
                tmpOutStr += "+\(bgImagePath)\n"
            }
            if let bgMusicPath = singlePageDatas[i].bgMusicPath {
                tmpOutStr += "-\(bgMusicPath)\n"
            }
            if let characters = singlePageDatas[i].characters {
                tmpOutStr += "~\n"
                for character in characters {
                    tmpOutStr += "@\(character.name)\n"
                    if let from = character.from {
                        tmpOutStr += "#\(from)\n"
                    }
                    tmpOutStr += "$\(character.content)\n"
                    if let emote = character.emote {
                        tmpOutStr += "%\(emote.rawValue)\n"
                    }
                    tmpOutStr += "^\(character.expression)\n"
                    if let symbol = character.symbol {
                        tmpOutStr += "&\(symbol.rawValue)\n"
                    }
                    tmpOutStr += "*\(character.position)\n"
                    if character.id != characters[characters.count - 1].id {
                        tmpOutStr += "√\n"
                    }
                }
                tmpOutStr += "`\n"
            }
            if choiceDatas[i] != nil {
                tmpOutStr += "=\n"
                for singleChoice in choiceDatas[i]! {
                    tmpOutStr += "\(singleChoice)\n"
                }
                tmpOutStr += "=\n"
            }
        }
        return tmpOutStr
    }
}

func GetClosestSize(sourceWidth: Double, sourceHeight: Double, matchWidth: Double, matchHeight: Double, dividedStep: Double = 1.2) -> CGSize {
    var tmpWidth = sourceWidth
    var tmpHeight = sourceHeight
    var totalDivided = 1.0
    while tmpWidth > matchWidth {
        tmpWidth /= dividedStep
        totalDivided *= dividedStep
    }
    tmpHeight = sourceHeight / totalDivided
    if tmpHeight > matchHeight {
        var subDivided = 1.0
        while tmpHeight > matchHeight {
            tmpHeight /= dividedStep
            subDivided *= dividedStep
        }
        tmpWidth /= subDivided
    }
    return CGSize(width: tmpWidth, height: tmpHeight)
}

#Preview {
    FSEditorView(projName: "Test")
}
