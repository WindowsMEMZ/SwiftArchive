//
//  ContentView.swift
//  BAGen
//
//  Created by WindowsMEMZ on 2023/10/1.
//

import AVKit
import SwiftUI
import DarockKit
import Alamofire
import ZipArchive
import CommonCrypto

let globalAppVersion = 100

struct ContentView: View {
    @AppStorage("ResVersion") var resVersion = 0
    @AppStorage("FinishedDownloadVer") var finishedDownloadVer = 0 // After Download(But not finish unzip), Set this to serverVer
    let bgAvplayer = AVPlayer(url: Bundle.main.url(forResource: "title", withExtension: "mp4")!)
    let bgAudioPlayer = try? AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "Theme_01", withExtension: "wav")!)
    @State var statusText = "正在检查更新..."
    @State var loadingImageRotation = 0.0
    @State var isDownloading = false
    @State var downloadProgress = 0.0
    @State var downloadProgressText = ""
    @State var isFinished = false
    var body: some View {
        ZStack {
            VideoPlayerView(player: bgAvplayer)
                .ignoresSafeArea()
            VStack {
                HStack {
                    Spacer()
                    BAButton(action: {
//                        resVersion = 100
                        nowScene = .EachCharacters
                    }, label: "Test")
                }
                Spacer()
                if isFinished {
                    ZStack(alignment: .center) {
                        Image("TapToStartBGImage")
                            .resizable()
                            .frame(width: 500, height: 20)
//                            .overlay {
//                                Color(hex: 0x3FC2F9, alpha: 0.5)
//                                
//                            }
                        BAText("TAP TO START", fontSize: 24)
                    }
                    .offset(y: UIScreen.main.bounds.height / 2 - 120)
                    Spacer()
                }
                if !isFinished {
                    if isDownloading {
                        ProgressView(value: downloadProgress, total: 1.0)
                            .progressViewStyle(CustomProgressBarStyle())
                    }
                    HStack {
                        Image("LoadingImage")
                            .resizable()
                            .frame(width: 13, height: 13)
                            .rotationEffect(.degrees(loadingImageRotation))
                            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: loadingImageRotation)
                            .onAppear {
                                loadingImageRotation = -360
                            }
                        BAText(statusText, fontSize: 12)
                        Spacer()
                        if isDownloading {
                            BAText(downloadProgressText, fontSize: 12)
                        }
                    }
                }
            }
        }
        .onTapGesture {
            if isFinished {
                debugPrint("Intro")
                ChangeScene(to: .TypeChoose)
            }
        }
        .onAppear {
            bgAvplayer.play()
            bgAudioPlayer?.volume = 0.9
            bgAudioPlayer?.numberOfLoops = -1
            bgAudioPlayer?.play()
            
            DarockKit.Network.shared.requestString("https://api.darock.top/bagen/update/app/check") { respStr, isSuccess in
                if isSuccess {
                    if let serverAppVer = Int(respStr) {
                        if serverAppVer <= globalAppVersion {
                            DarockKit.Network.shared.requestString("https://api.darock.top/bagen/update/check") { respStr, isSuccess in
                                if isSuccess {
                                    if let serverVer = Int(respStr) {
                                        if resVersion < serverVer {
                                            if finishedDownloadVer >= serverVer, let filePath = UserDefaults.standard.string(forKey: "WaitToUnzipFilePath") {
                                                UnzipArchive(filePath: filePath, serverVer: serverVer)
                                            } else {
                                                StartDownload(serverVer: serverAppVer)
                                            }
                                        } else {
                                            isFinished = true
                                        }
                                    } else {
                                        statusText = "检查更新时出现错误"
                                    }
                                } else {
                                    statusText = "检查更新时出现错误"
                                }
                            }
                        } else {
                            statusText = "需要更新客户端"
                        }
                    } else {
                        statusText = "检查更新时出现错误"
                    }
                }
            }
        }
    }
    func StartDownload(serverVer: Int) {
        statusText = "正在准备更新..."
        DarockKit.Network.shared.requestString("https://api.darock.top/bagen/update/link") { respStr, isSuccess in
            if isSuccess {
                isDownloading = true
                statusText = "正在更新..."
                let downloadLink = respStr.apiFixed()
                let destination: DownloadRequest.Destination = { _, _ in
                    let documentsURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                    let fileURL = documentsURL.appendingPathComponent("res\(serverVer).zip")
                    
                    return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
                }
                let resumeData = UserDefaults.standard.data(forKey: "UpdateDownloadResumeData\(serverVer)")
                if resumeData != nil {
                    debugPrint("Resume Downloading...")
                    AF.download(resumingWith: resumeData!, to: destination)
                        .downloadProgress { p in
                            downloadProgress = p.fractionCompleted
                            downloadProgressText = "\(String(format: "%.2f", downloadProgress * 100))% [\(String(format: "%.2f", Double(p.completedUnitCount) / 1024 / 1024))MB / \(String(format: "%.2f", Double(p.totalUnitCount) / 1024 / 1024))MB]"
                        }
                        .response { r in
                            DownloadResponseHander(r, serverVer: serverVer)
                        }
                } else {
                    debugPrint("Start a New Downloading...")
                    AF.download(downloadLink, to: destination)
                        .downloadProgress { p in
                            downloadProgress = p.fractionCompleted
                            downloadProgressText = "\(String(format: "%.2f", downloadProgress * 100))% [\(String(format: "%.2f", Double(p.completedUnitCount) / 1024 / 1024))MB / \(String(format: "%.2f", Double(p.totalUnitCount) / 1024 / 1024))MB]"
                        }
                        .response { r in
                            DownloadResponseHander(r, serverVer: serverVer)
                        }
                }
            } else {
                statusText = "无法获取更新链接"
            }
        }
    }
    func DownloadResponseHander(_ r: AFDownloadResponse<URL?>, serverVer: Int) {
        if r.error == nil, let filePath = r.fileURL?.path {
            debugPrint(filePath)
            statusText = "验证下载档案中..."
            if let fMd5 = fileMD5(url: URL(fileURLWithPath: filePath)) {
                DarockKit.Network.shared.requestString("https://api.darock.top/bagen/update/fmd5") { respStr, isSuccess in
                    if isSuccess {
                        if respStr.apiFixed() == fMd5 {
                            finishedDownloadVer = serverVer
                            UserDefaults.standard.set(filePath, forKey: "WaitToUnzipFilePath")
                            UnzipArchive(filePath: filePath, serverVer: serverVer)
                        } else {
                            statusText = "档案摘要值不正确,正在重启下载..."
                            UserDefaults.standard.removeObject(forKey: "UpdateDownloadResumeData\(serverVer)")
                            StartDownload(serverVer: serverVer)
                        }
                    } else {
                        statusText = "获取在线校验摘要时出错"
                    }
                }
            } else {
                statusText = "无法获取档案校验摘要"
            }
        } else {
            statusText = "下载失败"
            UserDefaults.standard.set(r.resumeData, forKey: "UpdateDownloadResumeData\(serverVer)")
        }
    }
    func UnzipArchive(filePath: String, serverVer: Int) {
        statusText = "正在解压..."
        Task {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("res/")
            SSZipArchive.unzipFile(atPath: filePath, toDestination: fileURL.path, overwrite: true, password: nil, progressHandler: { (fileName, info, nowFileCount, totalFileCount) in
                downloadProgress = Double(nowFileCount) / Double(totalFileCount)
                downloadProgressText = "\(String(format: "%.2f", downloadProgress * 100))% [\(nowFileCount)/\(totalFileCount)]"
            }, completionHandler: { (path, isSuccess, error) in
                if isSuccess {
                    UserDefaults.standard.removeObject(forKey: "WaitToUnzipFilePath")
                    isFinished = true
                    resVersion = serverVer
                } else {
                    statusText = "解压时出现错误"
                }
            })
        }
    }
    
    struct CustomProgressBarStyle: ProgressViewStyle {
        func makeBody(configuration: Configuration) -> some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .frame(width: geometry.size.width, height: 10)
                        .foregroundColor(.black)
                        .opacity(0.6)

                    RoundedRectangle(cornerRadius: 5)
                        .frame(width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0), height: 10)
                        .foregroundColor(Color(hex: 0x3FC2F9))
                }
            }
            .frame(height: 10)
        }
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    var player : AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false //Important to not show any native videoplayer controls
        controller.videoGravity = .resizeAspectFill
        loopVideo(player: player)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        
    }
    
    func loopVideo(player p: AVPlayer) {
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: p.currentItem, queue: nil) { notification in
            p.seek(to: .zero)
            p.play()
        }
    }
}

func fileMD5(url: URL) -> String? {
    // 打开文件，创建文件句柄
    let file = FileHandle(forReadingAtPath: url.path)
    guard file != nil else { return nil }
    
    // 创建 CC_MD5_CTX 上下文对象
    var context = CC_MD5_CTX()
    CC_MD5_Init(&context)
    
    // 读取文件数据并更新上下文对象
    while autoreleasepool(invoking: {
        let data = file?.readData(ofLength: 1024)
        if data?.count == 0 {
            return false
        }
        data?.withUnsafeBytes { buffer in
            CC_MD5_Update(&context, buffer.baseAddress, CC_LONG(buffer.count))
        }
        return true
    }) {}
    
    // 计算 MD5 值并关闭文件
    var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    CC_MD5_Final(&digest, &context)
    file?.closeFile()
    
    // 将 MD5 值转换为字符串格式
    let md5String = digest.map { String(format: "%02hhx", $0) }.joined()
    return md5String
}

#Preview {
    ContentView()
}
