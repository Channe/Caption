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
    private(set) var font: UIFont
    
    private(set) var textX: CGFloat
    private(set) var textY: CGFloat
    
    // 仔细设置字幕的 frame，以便播放时和导出时字幕位置一致
    private(set) var textXRate: CGFloat? = nil
    private(set) var textYRate: CGFloat? = nil
    
    init(text: String, timestamp:TimeInterval, duration: TimeInterval, font: UIFont, textX: CGFloat = 20, textY: CGFloat = 260) {
        
        self.text = text
        self.timeRange = CMTimeRange(start: CMTime(seconds: timestamp, preferredTimescale: 600),
                                     duration: CMTime(seconds: duration, preferredTimescale: 600))
        self.font = font
        
        self.textX = textX
        self.textY = textY
        
        super.init()
        
    }
    
    // 预览时，字幕宽高使用显示控件的宽高；
    func displayLayer(textX:CGFloat, textY:CGFloat, superWidth: CGFloat, superHeight: CGFloat) -> CALayer {
        
        self.textXRate = textX / superWidth
        self.textYRate = textY / superHeight
        
        return buildLayer(textX: textX, textY: textY, superWidth: superWidth)
    }
    
    // 导出时，字幕宽高使用视频本身的宽高；
    func exportLayer(superWidth: CGFloat, superHeight: CGFloat) -> CALayer {
        
        let textX = self.textXRate! * superWidth
        let textY = self.textYRate! * superHeight
        
        return buildLayer(textX: textX, textY: textY, superWidth: superWidth)
    }
    
    private func buildLayer(textX:CGFloat, textY:CGFloat, superWidth: CGFloat) -> CALayer {
        
        // 字幕宽度固定，高度根据字体动态计算
        let textWidth = superWidth - textX*2
        let textHeight = self.text.height(withConstrainedWidth: textWidth, font: self.font)
        let textFrame = CGRect(x: textX, y: textY, width: textWidth, height: textHeight)
        
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(x: textX, y: textY, width: textWidth, height: textHeight)
        // 默认隐藏，通过淡入动画来显示
        parentLayer.opacity = 0.0
        
        let textLayer = CATextLayer()
        textLayer.string = self.text
        textLayer.frame = CGRect(origin: .zero, size: textFrame.size)
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.isWrapped = true
        textLayer.alignmentMode = .left
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
        
        // fadeinfadeout
        let animation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.opacity))
        
        // 淡入：从透明到不透明，淡出：再从不透明到透明
        animation.values = [0.0, 1.0, 1.0, 0.0]
        // 每段动画执行的时间点，20%的时间淡入，20%的时间淡出
        animation.keyTimes = [0.0, 0.2, 0.8, 1.0]
        
        //TODO: qianlei animation.beginTime
        // 设置起始时间，如果要表示影片片头，不能用 0.0 来赋值 beginTime，因为 CoreAnimation 会将 0.0 的 beginTime 转为 CACurrentMediaTime()，所以要用 AVCoreAnimationBeginTimeAtZero 来代替
        animation.beginTime = CMTimeGetSeconds(self.timeRange.start)
//        animation.beginTime = CMTimeGetSeconds(CMTime(seconds: 1, preferredTimescale: 1))
        
        animation.duration = CMTimeGetSeconds(self.timeRange.duration)
        
        animation.isRemovedOnCompletion = false
        
        parentLayer.add(animation, forKey: nil)
        
        return parentLayer
    }
    
}
