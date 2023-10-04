//
//  PathFileChooserView.swift
//  BAGen
//
//  Created by memz233 on 2023/10/4.
//

import AVKit
import SwiftUI

struct PathFileChooserView: View {
    var path: String
    var previewType: PreviewType
    var prompt: String = "选择"
    @Binding var returnPath: String
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State var filePaths = [String]()
    @State var selectedIndex = -1
    @State var musicPreviewer: AVAudioPlayer? = AVAudioPlayer()
    var body: some View {
        ZStack {
            List {
                Text(prompt)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                if filePaths.count != 0 {
                    ForEach(0..<filePaths.count, id: \.self) { i in
                        Button(action: {
                            selectedIndex = i
                            returnPath = filePaths[i]
                            if previewType == .music {
                                musicPreviewer?.stop()
                                musicPreviewer = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: filePaths[i]))
                                musicPreviewer?.numberOfLoops = -1
                                musicPreviewer?.play()
                            }
                        }, label: {
                            HStack {
                                if selectedIndex == i {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                                if previewType == .image {
                                    Image(uiImage: UIImage(data: try! Data(contentsOf: URL(fileURLWithPath: filePaths[i])))!)
                                        .resizable()
                                        .frame(width: GetClosestSize(sourceWidth: UIImage(data: try! Data(contentsOf: URL(fileURLWithPath: filePaths[i])))!.size.width, sourceHeight: UIImage(data: try! Data(contentsOf: URL(fileURLWithPath: filePaths[i])))!.size.height, matchWidth: 240, matchHeight: 180).width, height: GetClosestSize(sourceWidth: UIImage(data: try! Data(contentsOf: URL(fileURLWithPath: filePaths[i])))!.size.width, sourceHeight: UIImage(data: try! Data(contentsOf: URL(fileURLWithPath: filePaths[i])))!.size.height, matchWidth: 240, matchHeight: 180).height)
                                }
                                Text(filePaths[i].split(separator: "/")[filePaths[i].split(separator: "/").count - 1])
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                        })
                    }
                }
            }
            HStack {
                Spacer()
                VStack {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text("完成")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.blue)
                    })
                    .padding(20)
                    Spacer()
                }
            }
        }
        .onAppear {
            let rootFiles = AppFileManager(path: path).GetRoot()!
            for file in rootFiles {
                let path = "\(AppFileManager(path: "").GetPath("").path)\(path)/\(file["name"]!)"
                if !path.split(separator: "/").last!.hasPrefix(".") {
                    filePaths.append(path)
                }
            }
            filePaths.sort(by: { i, j in
                let li = i.split(separator: "/").last!
                let lj = j.split(separator: "/").last!
                return li < lj
            })
        }
    }
    
    public enum PreviewType {
        case none
        case image
        case music
    }
}

#Preview {
    // Do Not Preview
    PathFileChooserView(path: "", previewType: .none, returnPath: .constant(""))
}
