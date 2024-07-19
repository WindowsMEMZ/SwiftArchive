//
//  FeedbackView.swift
//  BAGen
//
//  Created by memz233 on 2023/10/15.
//

import SwiftUI
import DarockKit

fileprivate let globalStates: [LocalizedStringKey] = [
    "未标记",
    "按预期工作",
    "无法修复",
    "问题重复",
    "搁置",
    "正在修复",
    "已在未来版本修复",
    "已修复",
    "正在加载",
    "未能复现",
    "问题并不与App相关",
    "需要更多细节",
    "被删除"
]
fileprivate let globalStateColors = [
    Color.secondary,
    Color.red,
    Color.red,
    Color.red,
    Color.orange,
    Color.orange,
    Color.orange,
    Color.green,
    Color.secondary,
    Color.red,
    Color.secondary,
    Color.orange,
    Color.red
]
fileprivate let globalStateIcons = [
    "minus",
    "curlybraces",
    "xmark",
    "arrow.trianglehead.pull",
    "books.vertical",
    "hammer",
    "clock.badge.checkmark",
    "checkmark",
    "ellipsis",
    "questionmark",
    "bolt.horizontal",
    "arrowshape.turn.up.backward.badge.clock",
    "xmark.square.fill"
]

struct FeedbackView: View {
    @Environment(\.dismiss) var dismiss
    @State var feedbackIds = [String]()
    @State var badgeOnIds = [String]()
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: { NewFeedbackView() }, label: {
                        Label("新建反馈", systemImage: "exclamationmark.bubble.fill")
                    })
                }
                if feedbackIds.count != 0 {
                    Section {
                        ForEach(0..<feedbackIds.count, id: \.self) { i in
                            NavigationLink(destination: { FeedbackDetailView(id: feedbackIds[i]) }, label: {
                                HStack {
                                    if badgeOnIds.contains(feedbackIds[i]) {
                                        Image(systemName: "1.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    Text("ID: \(feedbackIds[i])")
                                }
                            })
                            .swipeActions {
                                Button(role: .destructive, action: {
                                    feedbackIds.remove(at: i)
                                    UserDefaults.standard.set(feedbackIds, forKey: "RadarFBIDs")
                                }, label: {
                                    Image(systemName: "xmark.bin.fill")
                                })
                            }
                        }
                    } header: {
                        Text("发送的反馈")
                    }
                }
            }
            .navigationTitle("反馈助理")
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
                feedbackIds = UserDefaults.standard.stringArray(forKey: "RadarFBIDs") ?? [String]()
                badgeOnIds.removeAll()
                for id in feedbackIds {
                    DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/radar/details/SwiftArchive/\(id)") { respStr, isSuccess in
                        if isSuccess {
                            let repCount = respStr.apiFixed().components(separatedBy: "---").count - 1
                            let lastViewCount = UserDefaults.standard.integer(forKey: "RadarFB\(id)ReplyCount")
                            if repCount > lastViewCount {
                                badgeOnIds.append(id)
                            }
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled()
    }
    
    struct NewFeedbackView: View {
        @Environment(\.dismiss) var dismiss
        @State var titleInput = ""
        @State var contentInput = ""
        @State var feedbackType = 0
        @State var isSending = false
        var body: some View {
            List {
                Section {
                    TextField("标题", text: $titleInput)
                } header: {
                    Text("请为你的反馈提供描述性的标题：")
                } footer: {
                    Text("示例：导出图片时出现错误")
                }
                Section {
                    TextField("描述", text: $contentInput, axis: .vertical)
                } header: {
                    Text("请描述该问题以及重现问题的步骤：")
                } footer: {
                    Text("""
                        请包括：
                        - 问题的清晰描述
                        - 逐步说明重现问题的详细步骤（如果可能）
                        - 期望的结果
                        - 当前所示结果
                        """)
                }
                Section {
                    Picker("反馈类型", selection: $feedbackType) {
                        Text("错误/异常行为").tag(0)
                        Text("建议").tag(1)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("提交反馈")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        sendFeedback()
                    }, label: {
                        if !isSending {
                            Image(systemName: "paperplane.fill")
                        } else {
                            ProgressView()
                        }
                    })
                    .disabled(isSending)
                }
            }
            .onAppear {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { isGrand, _ in
                    DispatchQueue.main.async {
                        if isGrand {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                }
            }
        }
        
        func sendFeedback() {
            if titleInput == "" {
                AlertKitAPI.present(title: "标题不能为空", icon: .error, style: .iOS17AppleMusic, haptic: .error)
                return
            }
            isSending = true
            let msgToSend = """
            \(titleInput)
            State：0
            Type：\(feedbackType)
            Content：\(contentInput)
            Time：\(Date.now.timeIntervalSince1970)
            Version：v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String) Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)
            OS：\(UIDevice.current.systemVersion)
            NotificationToken：\(UserDefaults.standard.string(forKey: "UserNotificationToken") ?? "None")
            Sender: User
            """
            DarockKit.Network.shared
                .requestString("https://fapi.darock.top:65535/feedback/submit/anony/SwiftArchive/\(msgToSend.base64Encoded().replacingOccurrences(of: "/", with: "{slash}"))") { respStr, isSuccess in
                    if isSuccess {
                        if Int(respStr) != nil {
                            var arr = UserDefaults.standard.stringArray(forKey: "RadarFBIDs") ?? [String]()
                            arr.insert(respStr, at: 0)
                            UserDefaults.standard.set(arr, forKey: "RadarFBIDs")
                            AlertKitAPI.present(title: "已发送", icon: .done, style: .iOS17AppleMusic, haptic: .success)
                            dismiss()
                        } else {
                            AlertKitAPI.present(title: "服务器错误", icon: .error, style: .iOS17AppleMusic, haptic: .error)
                        }
                    }
                }
        }
    }
    struct FeedbackDetailView: View {
        var id: String
        private let projName = "SwiftArchive"
        @Environment(\.dismiss) var dismiss
        @State var feedbackText = ""
        @State var formattedTexts = [String]()
        @State var replies = [[String]]()
        @State var isNoReply = true
        @State var isReplyPresented = false
        @State var replyInput = ""
        @State var isReplySubmitted = false
        @State var isReplyDisabled = false
        var body: some View {
            List {
                if formattedTexts.count != 0 {
                    getView(from: formattedTexts)
                }
                if !isNoReply {
                    ForEach(0..<replies.count, id: \.self) { i in
                        getView(from: replies[i], isReply: true)
                    }
                }
                Section {
                    Button(action: {
                        isReplyPresented = true
                    }, label: {
                        Label("回复", systemImage: "arrowshape.turn.up.left.2")
                    })
                    .disabled(isReplyDisabled)
                } footer: {
                    if isReplyDisabled {
                        Text("此反馈已关闭，若要重新进行反馈，请创建一个新的反馈")
                    }
                }
            }
            .sheet(isPresented: $isReplyPresented, onDismiss: {
                refresh()
            }, content: {
                TextField("回复信息", text: $replyInput) {
                    if isReplySubmitted {
                        return
                    }
                    isReplySubmitted = true
                    if replyInput != "" {
                        let enced = """
                        Content：\(replyInput)
                        Sender：User
                        Time：\(Date.now.timeIntervalSince1970)
                        """.base64Encoded().replacingOccurrences(of: "/", with: "{slash}")
                        DarockKit.Network.shared
                            .requestString("https://fapi.darock.top:65535/radar/reply/SwiftArchive/\(id)/\(enced)") { respStr, isSuccess in
                                if isSuccess {
                                    if respStr.apiFixed() == "Success" {
                                        refresh()
                                        replyInput = ""
                                        isReplyPresented = false
                                    } else {
                                        AlertKitAPI.present(title: "未知错误", icon: .error, style: .iOS17AppleMusic, haptic: .error)
                                    }
                                    isReplySubmitted = false
                                }
                            }
                    }
                }
            })
            .navigationTitle(id)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                refresh()
            }
        }
        
        @inline(__always)
        func refresh() {
            DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/radar/details/\(projName)/\(id)") { respStr, isSuccess in
                if isSuccess {
                    formattedTexts.removeAll()
                    replies.removeAll()
                    feedbackText = respStr.apiFixed().replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\\"", with: "\"")
                    let spd = feedbackText.split(separator: "\n")
                    for text in spd {
                        if text == "---" { break }
                        formattedTexts.append(String(text))
                    }
                    debugPrint(formattedTexts)
                    if feedbackText.split(separator: "---").count > 1 {
                        let repliesText = Array(feedbackText.split(separator: "---").dropFirst()).map { String($0) }
                        for text in repliesText {
                            let spd = text.split(separator: "\n").map { String($0) }
                            var tar = [String]()
                            for lt in spd {
                                tar.append(lt)
                                if _slowPath(lt.hasPrefix("State：")) {
                                    if let st = Int(String(lt.dropFirst(6))) {
                                        isReplyDisabled = st == 1 || st == 2 || st == 3 || st == 7 || st == 10
                                    }
                                }
                            }
                            replies.append(tar)
                        }
                        
                        isNoReply = false
                    }
                    UserDefaults.standard.set(feedbackText.split(separator: "---").count, forKey: "RadarFB\(id)ReplyCount")
                }
            }
        }
        
        @ViewBuilder
        func getView(from: [String], isReply: Bool = false) -> some View {
            VStack {
                ForEach(0..<from.count, id: \.self) { j in
                    if from[j].hasPrefix("Sender") {
                        HStack {
                            Text(from[j].dropFirst(7))
                                .font(.system(size: 18))
                                .bold()
                            Spacer()
                        }
                    }
                }
                ForEach(0..<from.count, id: \.self) { j in
                    if from[j].hasPrefix("Time") {
                        if let intt = Double(String(from[j].dropFirst(5))) {
                            HStack {
                                Text({ () -> String in
                                    let df = DateFormatter()
                                    df.dateFormat = "yyyy-MM-dd hh:mm:ss"
                                    return df.string(from: Date(timeIntervalSince1970: intt))
                                }())
                                .font(.system(size: 15))
                                .foregroundStyle(Color.gray)
                                Spacer()
                            }
                        }
                    }
                }
                Divider()
                if !isReply {
                    HStack {
                        Text(from[0])
                            .font(.system(size: 20))
                            .bold()
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    Divider()
                }
                ForEach(0...from.count - 1, id: \.self) { i in
                    if !(!from[i].contains("：") && !from[i].contains(":") && i == 0) && (!from[i].hasPrefix("Sender")) && (!from[i].hasPrefix("Time")) {
                        // ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~     ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~      ^~~~~~~~~~~~~~~~~~~~~~~~~~~
                        //                     Not Title                                          Not Sender                         Not Time
                        if (from[i].contains("：") && from[i] != "：" ? from[i].split(separator: "：")[0] : "") != "" {
                            HStack {
                                Text(from[i].contains("：") && from[i] != "：" ? String(from[i].split(separator: "：")[0]).titleReadable() : "")
                                    .font(.system(size: 20))
                                    .bold()
                                Spacer()
                            }
                        }
                        HStack {
                            if (from[i].contains("：") && from[i] != "：" ? from[i].split(separator: "：")[0] : "") == "State" {
                                if let index = Int(from[i].split(separator: "：").count > 1 ? String(from[i].split(separator: "：")[1]) : from[i]) {
                                    HStack {
                                        Group {
                                            Image(systemName: globalStateIcons[index])
                                            Text(globalStates[index])
                                        }
                                        .foregroundStyle(globalStateColors[index])
                                        .font(.system(size: 16))
                                    }
                                } else {
                                    Text(from[i].split(separator: "：").count > 1 ? String(from[i].split(separator: "：")[1]) : from[i])
                                        .font(.system(size: 16))
                                }
                            } else if (from[i].contains("：") && from[i] != "：" ? from[i].split(separator: "：")[0] : "") == "NotificationToken" {
                                Text("[Hex Data]")
                                    .font(.system(size: 16))
                            } else if (from[i].contains("：") && from[i] != "：" ? from[i].split(separator: "：")[0] : "") == "NearestHistories" {
                                Text("[Privacy Hidden]")
                                    .font(.system(size: 16))
                            } else if (from[i].contains("：") && from[i] != "：" ? from[i].split(separator: "：")[0] : "") == "Settings" {
                                Text("[Privacy Hidden]")
                                    .font(.system(size: 16))
                            } else if (from[i].contains("：") && from[i] != "："
                                       ? from[i].split(separator: "：")[0]
                                       : "") == "AddDuplicateDelete"
                                        || (from[i].contains("：") && from[i] != "："
                                            ? from[i].split(separator: "：")[0]
                                            : "") == "DuplicateTo",
                                      let goId = Int(from[i].split(separator: "：")[1]) {
                                Text("FB\(projName.projNameLinked())\(String(goId))")
                            } else {
                                Text(from[i].split(separator: "：").count > 1 ? String(from[i].split(separator: "：")[1]).dropLast("\\") : from[i].dropLast("\\"))
                                    .font(.system(size: 16))
                            }
                            Spacer()
                        }
                        if i != from.count - 1 {
                            Spacer()
                                .frame(height: 10)
                        }
                    }
                }
            }
        }
    }
}

extension String {
    func dropFirst(_ k: Character) -> String {
        if self.hasPrefix(String(k)) {
            return String(self.dropFirst())
        } else {
            return self
        }
    }
    func dropLast(_ k: Character) -> String {
        if self.hasSuffix(String(k)) {
            return String(self.dropLast())
        } else {
            return self
        }
    }
    func projNameLinked() -> Self {
        let shortMd5d = String(self.md5.prefix(8)).lowercased()
        let a2nchart: [Character: Int] = ["a": 0, "b": 1, "c": 2, "d": 3, "e": 4, "f": 5, "g": 6, "h": 7, "i": 8, "j": 9, "k": 0, "l": 1, "m": 2, "n": 3, "o": 4, "p": 5, "q": 6, "r": 7, "s": 8, "t": 9, "u": 0, "v": 1, "w": 2, "x": 3, "y": 4, "z": 5] // swiftlint:disable:this line_length
        var ced = ""
        for c in shortMd5d {
            if Int(String(c)) == nil {
                ced += String(a2nchart[c]!)
            } else {
                ced += String(c)
            }
        }
        return ced
    }
    func titleReadable() -> LocalizedStringKey {
        switch self {
        case "State":
            return "状态"
        case "Type":
            return "类型"
        case "Content":
            return "描述"
        case "Version":
            return "App 版本"
        case "OS":
            return "系统版本"
        case "DuplicateTo":
            return "与此反馈重复"
        case "AddDuplicateDelete":
            return "关联反馈"
        case "NotificationToken":
            return "通知令牌"
        case "Settings":
            return "设置"
        default:
            return LocalizedStringKey(self)
        }
    }
}
extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}
