//
//  MTRawEditorView.swift
//  BAGen
//
//  Created by memz233 on 2023/10/14.
//

import UIKit
import SwiftUI
import DarockKit
import AttributedString

struct MTRawEditorView: View {
    var projName: String
    @Environment(\.dismiss) var dismiss
    @State var fullFileContent: ASAttributedString = .init(string: "", .font(.monospacedSystemFont(ofSize: 14, weight: .regular)))
    @State var allCharacterIds = [String]()
    @State var isCodeHelpPresented = false
    @State var codeIssues = [CodeIssue]()
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text("退出")
                            .font(.system(size: 18, weight: .medium))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    })
                    .frame(maxWidth: .infinity)
                    .frame(width: 60, height: 48)
                    .background(.gray)
                    .cornerRadius(14)
                    .foregroundColor(.black)
                    Button(action: {
                        if codeIssues.count == 0 {
                            let filePath = AppFileManager(path: "MTProj").GetFilePath(name: projName).path
                            try! fullFileContent.value.string.write(toFile: filePath, atomically: true, encoding: .utf8)
                            DarockKit.UIAlert.shared.presentAlert(title: "成功", subtitle: "项目已保存", icon: .done, style: .iOS17AppleMusic, haptic: .success)
                        } else {
                            DarockKit.UIAlert.shared.presentAlert(title: "无法保存", subtitle: "需要修正所有问题", icon: .error, style: .iOS17AppleMusic, haptic: .error)
                        }
                    }, label: {
                        Text("保存")
                            .font(.system(size: 18, weight: .medium))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    })
                    .frame(maxWidth: .infinity)
                    .frame(width: 60, height: 48)
                    .background(.blue)
                    .cornerRadius(14)
                    .foregroundColor(.white)
                    Button(action: {
                        isCodeHelpPresented = true
                    }, label: {
                        Text("帮助")
                            .font(.system(size: 18, weight: .medium))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    })
                    .frame(maxWidth: .infinity)
                    .frame(width: 60, height: 48)
                    .background(.blue)
                    .cornerRadius(14)
                    .foregroundColor(.white)
                    .sheet(isPresented: $isCodeHelpPresented, content: { RawCodeHelpView() })
                }
                CodeTextEditor(text: $fullFileContent) {
                    highlightCode()
                }
                .scrollDismissesKeyboard(.interactively)
                List {
                    if codeIssues.count != 0 {
                        ForEach(0..<codeIssues.count, id: \.self) { i in
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Spacer()
                                Text(codeIssues[i].id)
                                Spacer()
                                Text(codeIssues[i].desc)
                                Spacer()
                                Text("行\(codeIssues[i].line)")
                            }
                        }
                    } else {
                        Text("无问题")
                    }
                }
                .frame(width: UIScreen.main.bounds.width, height: 100)
            }
            .navigationTitle("源文件编辑")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // Init Character IDs
            let allChatacterDatas = MTBase().getAllCharacterDatas()
            for chatacter in allChatacterDatas {
                allCharacterIds.append(chatacter.id)
            }
            
            let rStr = try! String(contentsOfFile: AppFileManager(path: "MTProj").GetFilePath(name: projName).path)
            fullFileContent = .init(string: rStr, .font(.monospacedSystemFont(ofSize: 14, weight: .regular)))
            highlightCode()
        }
    }
    
    struct RawCodeHelpView: View {
        @Environment(\.dismiss) var dismiss
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack {
                        Text("""
                        基本格式: 
                        文本对话: {角色 ID(String)}|{头像组下标(Int)}|{内容}|{ShowldShowAsNew(Bool)}
                        图片:    {角色 ID(String)}|{头像组下标(Int)}|"%%TImage%%*"(图像标记){图像 Base64|图像路径(./开头)}|{ShouldShowAsNew(Bool)}
                        按行分隔
                        角色 ID 为 "Sensei" 时显示消息由我方发出
                        角色 ID 为 "SpecialEvent" 时显示羁绊剧情, 此时内容为羁绊剧情对象
                        角色 ID 为 "System" 时显示系统信息
                        """)
                    }
                    .padding()
                }
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
    
    func highlightCode() {
        DispatchQueue(label: "com.Neinnko.BAGen.Source-Editor.SourceKit", qos: .userInitiated).async {
            let rawString = fullFileContent.value.string
            var newFull = ASAttributedString(string: fullFileContent.value.string, .font(.monospacedSystemFont(ofSize: 14, weight: .regular)))
            for cid in allCharacterIds {
                if rawString.contains(cid) {
                    let ranges = findRanges(in: rawString, for: cid)
                    for range in ranges {
                        newFull.add(attributes: [.foreground(.init(Color(hex: 0xA485CA)))], checkings: [.range(NSRange(range, in: rawString))])
                    }
                }
            }
            newFull.add(attributes: [.foreground(.blue)], checkings: [.regex("\\|[0-9]\\|")])
            if rawString.contains("Sensei") {
                for range in findRanges(in: rawString, for: "Sensei") {
                    newFull.add(attributes: [.foreground(.init(Color(hex: 0x0671A6))), .font(.monospacedSystemFont(ofSize: 14, weight: .semibold))], range: NSRange(range, in: rawString))
                }
            }
            if rawString.contains("System") {
                for range in findRanges(in: rawString, for: "System") {
                    newFull.add(attributes: [.foreground(.init(Color(hex: 0x0671A6))), .font(.monospacedSystemFont(ofSize: 14, weight: .semibold))], range: NSRange(range, in: rawString))
                }
            }
            if rawString.contains("SpecialEvent") {
                for range in findRanges(in: rawString, for: "SpecialEvent") {
                    newFull.add(attributes: [.foreground(.init(Color(hex: 0x0671A6))), .font(.monospacedSystemFont(ofSize: 14, weight: .semibold))], range: NSRange(range, in: rawString))
                }
            }
            if rawString.contains("false") {
                for range in findRanges(in: rawString, for: "false") {
                    newFull.add(attributes: [.foreground(.init(Color(hex: 0xAD4BA5))), .font(.monospacedSystemFont(ofSize: 14, weight: .semibold))], checkings: [.range(NSRange(range, in: rawString))])
                }
            }
            if rawString.contains("true") {
                for range in findRanges(in: rawString, for: "true") {
                    newFull.add(attributes: [.foreground(.init(Color(hex: 0xAD4BA5))), .font(.monospacedSystemFont(ofSize: 14, weight: .semibold))], checkings: [.range(NSRange(range, in: rawString))])
                }
            }
            if rawString.contains("|") {
                for range in findRanges(in: rawString, for: "|") {
                    newFull.add(attributes: [.foreground(.init(Color(hex: 0xCB291A))), .font(.monospacedSystemFont(ofSize: 14, weight: .semibold))], range: NSRange(range, in: rawString))
                }
            }
            
            checkCodeIssues(newFull)
        }
        
        func findRanges(in text: String, for searchText: String) -> [Range<String.Index>] {
            var searchStartIndex = text.startIndex
            var ranges: [Range<String.Index>] = []

            while let range = text.range(of: searchText, options: .caseInsensitive, range: searchStartIndex..<text.endIndex, locale: nil) {
                ranges.append(range)
                searchStartIndex = range.upperBound
            }

            return ranges
        }
    }
    func checkCodeIssues(_ newFull: ASAttributedString) {
        codeIssues.removeAll()
        // Check Code
        let spdByLine = newFull.value.string.split(separator: "\n").map({ return String($0) })
        for i in 0..<spdByLine.count {
            if (i == spdByLine.count - 1) && spdByLine[i] == "" { break }
            let spdEachPart = spdByLine[i].split(separator: "|").map { return String($0) }
            if spdEachPart.count == 4 {
                if !allCharacterIds.contains(spdEachPart[0]) && spdEachPart[0] != "Sensei" && spdEachPart[0] != "System" && spdEachPart[0] != "SpecialEvent" && !spdEachPart[0].contains("%^Split^@") {
                    codeIssues.append(.init(id: "MT003", desc: "角色 ID 不存在", line: i + 1))
                }
                if spdEachPart[3] != "false" && spdEachPart[3] != "true" {
                    codeIssues.append(.init(id: "MT004", desc: "ShouldShowAsNew 标记应当为Bool值", line: i + 1))
                }
            } else {
                if spdEachPart.count < 4 {
                    codeIssues.append(.init(id: "MT001", desc: "元素过少", line: i + 1))
                } else if spdEachPart.count > 4 {
                    codeIssues.append(.init(id: "MT002", desc: "元素过多", line: i + 1))
                }
            }
        }
        // Highlight Line with Issue
        var fullCopy = newFull
        for issue in codeIssues {
            let line = issue.line
            var hRangeStart = line - 1
            for i in 0..<line - 1 {
                hRangeStart += spdByLine[i].count
            }
            fullCopy.add(attributes: [.background(.init(Color(hex: 0xFFEFEE)))], range: NSRange(location: hRangeStart, length: spdByLine[line - 1].count + 1))
        }
        fullFileContent = fullCopy
    }
    
    struct CodeIssue {
        var id: String
        var desc: String
        var line: Int
    }
}

struct CodeTextEditor: UIViewRepresentable {
    @Binding var text: ASAttributedString
    var onChange: () -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.attributed.text = text
        return textView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        if uiView.attributed.text != text {
            let cursorRange = uiView.selectedRange
            let scrollOffset = uiView.contentOffset
            uiView.attributed.text = text
            uiView.selectedRange = cursorRange
            uiView.setContentOffset(scrollOffset, animated: false)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CodeTextEditor

        init(_ parent: CodeTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.attributed.text
            parent.onChange()
        }
    }
}
