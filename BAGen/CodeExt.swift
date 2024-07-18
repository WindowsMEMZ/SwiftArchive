//
//  CodeExt.swift
//  BAGen
//
//  Created by WindowsMEMZ on 2023/10/1.
//

import Photos
import SwiftUI
import DarockKit
import Foundation
import MobileCoreServices
import UniformTypeIdentifiers

/// BlueArchive 样式的文本
/// - Parameters:
///   - text: 文本
///   - fontSize: 字号
///   - textColor: 文本颜色
///   - isSystemd: 是否以原生SwiftUI渲染
///   - isBold: 是否加粗
/// - Returns: 文本视图
@ViewBuilder func BAText(_ text: String, fontSize: CGFloat = 18, textColor: Color = Color(hex: 0x27394F), isSystemd: Bool = false, isBold: Bool = true) -> some View {
    if !isSystemd {
        let pedStr = drawOutlineAttributedString(string: text, fontSize: fontSize, alignment: .left, textColor: UIColor(textColor), strokeWidth: -2, widthColor: .white)
        Text("\(pedStr)")
            .font(.custom("GyeonggiTitle", size: fontSize))
            .fontWeight(.bold)
    } else {
        Text(text)
            .font(.custom("GyeonggiTitle", size: fontSize))
            .fontWeight(isBold ? .bold : .regular)
            .foregroundColor(textColor)
    }
}
private func drawOutlineAttributedString(
    string: String,
    fontSize: CGFloat,
    alignment: NSTextAlignment,
    textColor: UIColor,
    strokeWidth: CGFloat,
    widthColor: UIColor) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineHeightMultiple = 0.93
        let font = UIFont(name: "GyeonggiTitle", size: fontSize)!
        let boldFontDescriptor = font.fontDescriptor.withSymbolicTraits(.traitBold)!
        let boldFont = UIFont(descriptor: boldFontDescriptor, size: fontSize)
        let dic: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: boldFont,
            NSAttributedString.Key.paragraphStyle: paragraph,
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.strokeWidth: strokeWidth,
            NSAttributedString.Key.strokeColor: widthColor,
            NSAttributedString.Key.kern: 1
        ]
        var attributedText: NSMutableAttributedString!
        attributedText = NSMutableAttributedString(string: string, attributes: dic)
        return attributedText
}

/// BlueArchive 样式的按钮
/// - Parameters:
///   - action: 按下后执行的操作
///   - label: 按钮上的文字
///   - isHighlighted: 是否高亮按钮
///   - isSmallStyle: 是否显示为小号按钮
/// - Returns: 文本视图
@ViewBuilder func BAButton(action: @escaping () -> Void, label: String, isHighlighted: Bool = false, isSmallStyle: Bool = false) -> some View {
    ZStack(alignment: .center) {
        Image(isHighlighted ? "HighlightButtonImage" : "ButtonImage")
            .scaleEffect(isSmallStyle ? 0.7 : 1)
            .shadow(color: .black.opacity(0.9), radius: 3, x: 1, y: 2)
        BAText(label, fontSize: isSmallStyle ? 16 : 20)
    }
    .onTapGesture {
        action()
    }
}

/// BlueArchive 横屏上方的顶部栏
/// - Parameters:
///   - backAction: 返回按钮执行的操作
///   - navigationTitle: 导航文本
/// - Returns: 视图
@ViewBuilder func BATopBar(backAction: (() -> Void)? = nil, navigationTitle: String? = nil) -> some View {
    @State var isSettingsPresented = false
    ZStack {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(hex: 0xF7F9F9))
            .frame(height: 40)
            .shadow(color: .black.opacity(0.8), radius: 2, x: 1, y: 2)
        HStack {
            Image("TopBarLeftImage")
                .resizable()
                .frame(width: 150, height: 40)
                .cornerRadius(8)
            Spacer()
        }
        HStack {
            Spacer()
                .frame(width: 30)
            if let bac = backAction {
                Button(action: {
                    bac()
                }, label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: 0x3D578D))
                            .frame(width: 35, height: 35)
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                    }
                })
                .offset(y: 5)
            }
            if let nt = navigationTitle {
                BAText(nt, fontSize: 18, isSystemd: true)
            }
            Spacer()
            Group {
                Image("ActionPointImage")
                    .resizable()
                    .frame(width: 12, height: 20)
                BAText("114/114", fontSize: 16, isSystemd: true, isBold: false)
                Image(systemName: "plus")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: 0x5BCDFE))
                Text("/")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: 0xD0D4D9))
            }
            Group {
                Image("CMoneyImage")
                    .resizable()
                    .frame(width: 25, height: 20)
                BAText("10,224,509", fontSize: 16, isSystemd: true, isBold: false)
                Image(systemName: "plus")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: 0x5BCDFE))
                Text("/")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: 0xD0D4D9))
            }
            Group {
                Image("CyanStoneImage")
                    .resizable()
                    .frame(width: 17, height: 20)
                BAText("12,345", fontSize: 16, isSystemd: true, isBold: false)
                Image(systemName: "plus")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: 0x5BCDFE))
                Text("/")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: 0xD0D4D9))
            }
            Button(action: {
                isSettingsPresented = true
            }, label: {
                Image(systemName: "gearshape.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color(hex: 0x3D578D))
            })
            .fullScreenCover(isPresented: $isSettingsPresented, content: {SettingsView()})
            Spacer()
                .frame(width: 10)
        }
        .offset(y: 5)
    }
    .frame(height: 40)
    .offset(y: -30)
}

extension String {
    /// 文本中是否含有二创不适宜内容
    var isContainBads: Bool {
        if self.contains("狂暴雷普狼") {
            return true
        } else {
            return false
        }
    }
}

/// 获取全屏截图
/// - Returns: 截图
func captureScreenshot() -> UIImage {
    return UIApplication.shared.keyWindow!.asImage()
}
extension UIView {
    //将当前视图转为UIImage
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

/// 将Image保存到相册
/// - Parameter image: 要保存到Image
func saveImageToPhotoLibrary(image: UIImage) {
    PHPhotoLibrary.shared().performChanges {
        PHAssetChangeRequest.creationRequestForAsset(from: image)
    } completionHandler: { success, error in
        if success {
            print("图片已成功保存到相册。")
        } else if let error = error {
            print("保存图片到相册时发生错误: \(error)")
        }
    }
}
func saveVideoToPhotoLibrary(video: URL) {
    PHPhotoLibrary.shared().performChanges {
        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: video)
    } completionHandler: { success, error in
        if success {
            print("视频已成功保存到相册。")
        } else if let error = error {
            print("保存视频到相册时发生错误: \(error)")
        }
    }
}

/// 毫秒线程休眠
/// - Parameter milliseconds: 等待的毫秒数
func msleep(_ milliseconds: UInt32) {
    let microseconds = milliseconds * 1000 // 将微秒转换为毫秒
    usleep(microseconds)
}

/// 共享表单
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        
    }
}

struct UIImageTransfer: Transferable {
    let image: UIImage
    enum TransferError: Error {
        case importFailed
    }
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let uiImage = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            return UIImageTransfer(image: uiImage)
        }
    }
}

extension UTType {
    static var sapm: UTType {
        UTType(importedAs: "com.Neinnko.BAGen.sapm")
    }
}
