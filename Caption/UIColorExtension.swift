//
//  UIColorExtension.swift
//  ttbooster
//
//  Created by Qian on 2020/5/9.
//  Copyright © 2020 tt. All rights reserved.
//

import UIKit

extension UIColor {
    
    public convenience init(hex: String, a: CGFloat = 1) {
        let r, g, b: CGFloat
        let hexString = hex.replacingOccurrences(of: "#", with: "")
        
        let start = hexString.startIndex
        let hexColor = String(hexString[start...])
        
        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0
        scanner.scanHexInt64(&hexNumber)
        
        r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255
        g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255
        b = CGFloat(hexNumber & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b, alpha: a)
    }
    
    public convenience init(hex: Int, a: CGFloat = 1) {
        let r, g, b: CGFloat
        
        r = CGFloat((hex & 0xFF0000) >> 16) / 255
        g = CGFloat((hex & 0x00FF00) >> 8) / 255
        b = CGFloat(hex & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b, alpha: a)
    }

}
