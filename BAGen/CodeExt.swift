//
//  CodeExt.swift
//  BAGen
//
//  Created by WindowsMEMZ on 2023/10/1.
//

import SwiftUI
import DarockKit
import Foundation

@ViewBuilder func BAText(_ text: String, fontSize: CGFloat = 18) -> some View {
    let pedStr = drawOutlineAttributedString(string: text, fontSize: fontSize, alignment: .left, textColor: UIColor(Color(hex: 0x27394F)), strokeWidth: -1.5, widthColor: .white)
    Text("\(pedStr)")
        .font(.custom("MainFont_Bold", size: fontSize))
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
    let dic: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize),
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
