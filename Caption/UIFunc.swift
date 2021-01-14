//
//  UIFunc.swift
//
//
//  Created by Qian on 2020/5/12.
//  Copyright © 2020 tt. All rights reserved.
//

import UIKit

// iPad
let iPhoneDevice = (UIDevice.current.userInterfaceIdiom == .phone)
let iPadDevice = (UIDevice.current.userInterfaceIdiom == .pad)

/// 实际屏幕宽度
let IOS_WIDTH = UIScreen.main.bounds.width
/// 实际屏幕高度
let IOS_HEIGHT = UIScreen.main.bounds.height
/// 屏幕显示宽度，iPad 上为实际屏幕宽度的0.64
let SCREEN_WIDTH: CGFloat = {
    if iPadDevice {
        return IOS_WIDTH * 0.64
    } else {
        return IOS_WIDTH
    }
}()

/// 屏幕像素比例
let IOS_SCALE = UIScreen.main.scale


//MARK: - 全局内联函数

@inline(__always) func TTFont(_ size:Float) -> UIFont {
    return UIFont.systemFont(ofSize: CGFloat(size))
}

@inline(__always) func TTFontB(_ size:Float) -> UIFont {
    return UIFont.boldSystemFont(ofSize: CGFloat(size))
}

@inline(__always) func TTFontM(_ size:Float) -> UIFont {
    return UIFont.systemFont(ofSize: CGFloat(size), weight: .medium)
}

@inline(__always) func TTFontL(_ size:Float) -> UIFont {
    return UIFont.systemFont(ofSize: CGFloat(size), weight: .light)
}

@inline(__always) func TTColor(_ hex:String) -> UIColor {
    return UIColor(hex: hex)
}

@inline(__always) func TTColor(_ hex:String, a: CGFloat = 1) -> UIColor {
    return UIColor(hex: hex, a:a)
}

@inline(__always) func TTColor(_ hex:Int) -> UIColor {
    return UIColor(hex: hex)
}

@inline(__always) func TTImage(_ name:String) -> UIImage? {
    return UIImage(named: name)
}

@inline(__always) func TTImageView() -> UIImageView {
    let imgV = UIImageView(frame: .zero)
    imgV.backgroundColor = .systemGroupedBackground
    imgV.contentMode = .scaleAspectFill
    imgV.clipsToBounds = true
    return imgV
}

@inline(__always) func TTImageView(_ name:String) -> UIImageView {
    let imgV = UIImageView(image: TTImage(name))
    imgV.backgroundColor = .systemGroupedBackground
    imgV.contentMode = .scaleAspectFill
    imgV.clipsToBounds = true
    return imgV
}

@inline(__always) func TTImageView(_ image:UIImage?) -> UIImageView {
    let imgV = UIImageView(image: image)
    imgV.backgroundColor = .systemGroupedBackground
    imgV.contentMode = .scaleAspectFill
    imgV.clipsToBounds = true
    return imgV
}

@inline(__always) func TTButton(title:String, target: Any, action: Selector) -> UIButton {
    let btn = UIButton(frame: .zero)
    btn.setTitle(title, for: .normal)
    btn.setTitleColor(.black, for: .normal)
    btn.addTarget(target, action: action, for: .touchUpInside)
    btn.backgroundColor = .systemGroupedBackground
    return btn
}

@inline(__always) func TTButton(title:String, _ target: Any, _ action: Selector) -> UIButton {
    let btn = UIButton(frame: .zero)
    btn.setTitle(title, for: .normal)
    btn.setTitleColor(.black, for: .normal)
    btn.addTarget(target, action: action, for: .touchUpInside)
    btn.backgroundColor = .systemGroupedBackground
    return btn
}

@inline(__always) func TTButton(image:String, target: Any? = nil, action: Selector? = nil) -> UIButton {
    let btn = UIButton(frame: .zero)
    btn.setImage(TTImage(image), for: .normal)
    if target != nil && action != nil {
        btn.addTarget(target!, action: action!, for: .touchUpInside)
    }
    btn.backgroundColor = .systemGroupedBackground
    return btn
}

@inline(__always) func TTButton(image:String, _ target: Any? = nil, _ action: Selector? = nil) -> UIButton {
    let btn = UIButton(frame: .zero)
    btn.setImage(TTImage(image), for: .normal)
    if target != nil && action != nil {
        btn.addTarget(target!, action: action!, for: .touchUpInside)
    }
    btn.backgroundColor = .systemGroupedBackground
    return btn
}

@inline(__always) func TTButton(image:UIImage?, _ target: Any? = nil, _ action: Selector? = nil) -> UIButton {
    let btn = UIButton(frame: .zero)
    btn.setImage(image, for: .normal)
    if target != nil && action != nil {
        btn.addTarget(target!, action: action!, for: .touchUpInside)
    }
    btn.backgroundColor = .systemGroupedBackground
    return btn
}

@inline(__always) func TTLabel() -> UILabel {
    return TTLabel(fs: 16, c: .black, alignment: .left)
}

@inline(__always) func TTLabel(fontSize:Float = 16, color:Int = 0x333333, alignment: NSTextAlignment = .right) -> UILabel {
    return TTLabel(fs: fontSize, c: TTColor(color), alignment: alignment)
}

@inline(__always) func TTLabelM(fs:Float = 16, c:UIColor = .black) -> UILabel {
    return TTLabel(font: TTFontM(fs), color: c)
}

@inline(__always) func TTLabelB(fs:Float = 16, c:UIColor = .black) -> UILabel {
    return TTLabel(font: TTFontB(fs), color: c)
}

@inline(__always) func TTLabel(font:UIFont = TTFont(16), color:UIColor = .black, alignment: NSTextAlignment = .left) -> UILabel {
    let label = UILabel(frame: .zero)
    label.font = font
    label.textColor = color
    label.textAlignment = alignment
    label.text = "label"
    return label
}

@inline(__always) func TTLabel(fs:Float = 16, c:UIColor = .black, alignment: NSTextAlignment = .left) -> UILabel {
    let label = UILabel(frame: .zero)
    label.font = TTFont(fs)
    label.textColor = c
    label.textAlignment = alignment
    label.text = "label"
    return label
}

// MARK: - 精确UI

// 还原Sketch中的行间距
@inline(__always) func TTAttrs(_ lineHeight:CGFloat, font:UIFont, color:UIColor) -> [NSAttributedString.Key : Any] {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.maximumLineHeight = lineHeight
    paragraphStyle.minimumLineHeight = lineHeight
    
    paragraphStyle.lineBreakMode = .byWordWrapping
    
    let baselineOffset = (lineHeight - font.lineHeight) / 4
    let attrs:[NSAttributedString.Key : Any] = [.font:font, .paragraphStyle:paragraphStyle, .foregroundColor:color,.baselineOffset:baselineOffset]
    return attrs
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        
        let boundingBox = self.boundingRect(with: constraintRect, options: options, attributes: [.font: font], context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]

        let boundingBox = self.boundingRect(with: constraintRect, options: options, attributes: [.font: font], context: nil)

        return ceil(boundingBox.width)
    }
}

extension String {
    
    // 获取字符长度
    func charactersCount() -> Int {
        var total = 0
        for index in self.indices {
            let char = "\(self[index])"
            let length1 = char.lengthOfBytes(using: .utf16)
            let length2 = char.lengthOfBytes(using: .ascii)
            
            if length1 != length2 * 2  {
                total += length1
            } else {
                total += length2
            }
        }
        
        return total
    }
    
    // 取前多少个字符，文字的字符长度，ASCII码里的按一个字符算，其他按2个字符算
    func prefixCharactersCount(_ count:Int) -> String {
        let utf16Length = self.lengthOfBytes(using: .utf16)

        if  utf16Length < count {
            return self
        }
        
        var prefixLength = 0
        var total = 0
        for index in self.indices {
            if total >= count {
                break
            }
            let char = "\(self[index])"
            let length1 = char.lengthOfBytes(using: .utf16)
            let length2 = char.lengthOfBytes(using: .ascii)

            if length1 != length2 * 2  {
                prefixLength += 1
                total += length1
            } else {
                prefixLength += length2
                total += length2
            }
        }
        return String(self.prefix(prefixLength))
    }
}

extension String {
    var isNotEmpty: Bool {
        return !self.isEmptyString
    }
    var isEmptyString: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension Optional where Wrapped == String {
    var isNotEmptyString: Bool {
        return !self.isEmptyString
    }
    var isEmptyString: Bool {
        if let unwrapped = self {
            return unwrapped.isEmptyString
        } else {
            return true
        }
    }
}

//MARK: - 业务UI数据

// UI颜色

/// 各种透明度的白色
/// - Parameter alpha: 透明度
/// - Returns: 白色 #FFFFFF
@inline(__always) func TTWhiteColor(_ alpha:Float = 1) -> UIColor {
    return UIColor.white.withAlphaComponent(CGFloat(alpha))
}

/// 各种透明度的黑色
/// - Parameter alpha: 透明度
/// - Returns: 黑色 #000000
@inline(__always) func TTBlackColor(_ alpha:Float = 1) -> UIColor {
    return UIColor.black.withAlphaComponent(CGFloat(alpha))
}
