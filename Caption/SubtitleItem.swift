//
//  SubtitleItem.swift
//  Caption
//
//  Created by Qian on 2021/1/14.
//

import UIKit
import AVFoundation

class SubtitleItem: NSObject {
    
    private(set) var text: String
    private(set) var timeRange: CMTimeRange
    private(set) var bounds: CGRect
    private(set) var size: CGSize
    private(set) var font: UIFont
    
    init(text: String, timestamp:TimeInterval, duration: TimeInterval, size: CGSize, font: UIFont) {
        
        self.text = text
        self.timeRange = CMTimeRange(start: CMTime(seconds: timestamp, preferredTimescale: 600),
                                     duration: CMTime(seconds: duration, preferredTimescale: 600))
        self.size = size
        self.bounds = CGRect(origin: .zero, size: size)
        self.font = font
        
        super.init()
        
    }
    
    func buildLayer() -> CALayer {
        
        let parentLayer = CALayer()
        parentLayer.frame = self.bounds
        
        let textLayer = CATextLayer()
        textLayer.string = self.text
        textLayer.frame = self.bounds
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.isWrapped = true
        /*
         CATextLayer
         var font: CFTypeRef? { get set }
         private(set) var font: UIFont { get }
         
         UIFont 赋值给 CFTypeRef 并没有报错，但实际使用的字体大小并不是设置的20，而是36
         */
//        textLayer.font = self.font // 错误
        
        // 正确设置 font
        textLayer.font = CGFont(self.font.fontName as CFString)
        textLayer.fontSize = self.font.pointSize
        
        parentLayer.addSublayer(textLayer)
        
        let fadeInFadeOutAnimation = CAKeyframeAnimation(keyPath: "oopacity")
        fadeInFadeOutAnimation.values = [0.0, 1.0, 1.0, 0.0]
        fadeInFadeOutAnimation.keyTimes = [0.0, 0.2, 0.8, 1.0]
        fadeInFadeOutAnimation.beginTime = CMTimeGetSeconds(self.timeRange.start)
        fadeInFadeOutAnimation.duration = CMTimeGetSeconds(self.timeRange.duration)
        fadeInFadeOutAnimation.isRemovedOnCompletion = false
        
        parentLayer.add(fadeInFadeOutAnimation, forKey: nil)
        
        return parentLayer
    }
    
    
}
