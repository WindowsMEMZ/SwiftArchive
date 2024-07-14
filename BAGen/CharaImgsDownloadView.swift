//
//  TypeChooseView.swift
//  BAGen
//
//  Created by WindowsMEMZ on 2023/10/2.
//

import SwiftUI
import DarockKit

struct CharaImgsDownloadView: View {
    @State var downloadProgressTimer: Timer?
    @State var downloadProgress = Progress(totalUnitCount: 0)
    var body: some View {
        NavigationStack {
            NStack {
                ScrollView {
                    VStack {
                        NeuText("下载角色立绘/表情差分资源")
                        NeuProgressView(value: Float(downloadProgress.completedUnitCount), total: Float(downloadProgress.totalUnitCount), width: UIScreen.main.bounds.width - 30)
                        Text("\(String(format: "%.2f", Double(downloadProgress.completedUnitCount) / 1024 / 1024))MB / \(String(format: "%.2f", Double(downloadProgress.totalUnitCount) / 1024 / 1024))MB")
                    }
                    .padding()
                }
                .scrollIndicators(.never)
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            
            let resourceRequest = NSBundleResourceRequest(tags: ["CharaImg0"])
            resourceRequest.loadingPriority = NSBundleResourceRequestLoadingPriorityUrgent
            downloadProgressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                downloadProgress = resourceRequest.progress
            }
            resourceRequest.beginAccessingResources { error in
                downloadProgressTimer?.invalidate()
                downloadProgressTimer = nil
                if let error {
                    print(error)
                    DispatchQueue.main.async {
                        AlertKitAPI.present(title: error.localizedDescription, style: .iOS17AppleMusic)
                    }
                    return
                }
                
            }
        }
    }
}
