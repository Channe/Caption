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
    
    init(text: String, timestamp:TimeInterval, duration: TimeInterval, font: UIFont, textX: CGFloat = 20, textY: CGFloat = 360) {
        
        self.text = text
        self.timeRange = CMTimeRange(start: CMTime(seconds: timestamp, preferredTimescale: 600),
                                     duration: CMTime(seconds: duration, preferredTimescale: 600))
        self.font = font
        
        self.textX = textX
        self.textY = textY
        
        super.init()
        
    }
    
    private(set) var textWHRate: CGFloat? = nil
    private(set) var fontRate: CGFloat? = nil

    /*
     字幕大小取决于三种尺寸：控件宽高，视频在控件上缩放之后的宽高，视频本身宽高
     预览时，字幕宽高使用显示控件的宽高；
     导出时，字幕宽高使用视频本身的宽高；
     */
    // 预览时，字幕宽高使用显示控件的宽高；
    func getDisplayLayer(displayWidth: CGFloat, displayHeight: CGFloat) -> CALayer {
        print(#function)
        
        self.textXRate = self.textX / displayWidth
        self.textYRate = self.textY / displayHeight
        // 字幕宽度固定，高度根据字体动态计算
        let textWidth = displayWidth - textX * 2
        let textHeight = self.text.height(withConstrainedWidth: textWidth, font: self.font)
        self.textWHRate = textWidth / textHeight
        let textFrame = CGRect(x: textX, y: textY, width: textWidth, height: textHeight)

        self.fontRate = self.font.pointSize / textWidth
        
        return buildLayer(textFrame: textFrame, fontName: self.font.fontName, fontSize: self.font.pointSize)
    }
    
    // 导出时，字幕宽高使用视频本身的宽高；
    func getExportLayer(videoWidth: CGFloat, videoHeight: CGFloat) -> CALayer {
        print(#function)
        
        let textX = videoWidth * self.textXRate!
        let textY = videoHeight * self.textYRate!
        let textWidth = videoWidth - textX * 2
        let textHeight = textWidth / self.textWHRate!
        let textFrame = CGRect(x: textX, y: textY, width: textWidth, height: textHeight)

        let fontSize = textWidth * self.fontRate!
        
        return buildLayer(textFrame: textFrame, fontName: self.font.fontName, fontSize: fontSize)
    }
    
    private func buildLayer(textFrame:CGRect, fontName: String, fontSize: CGFloat) -> CALayer {
        print("buildLayer textFrame:\(textFrame)")
        print("buildLayer self.font:\(self.font)")
        print("buildLayer fontName:\(fontName)")
        print("buildLayer fontSize:\(fontSize)")

        let parentLayer = CALayer()
        parentLayer.frame = textFrame
        print("parentLayer.frame:\(parentLayer.frame)")
        // 默认隐藏，通过淡入动画来显示
        parentLayer.opacity = 0.0
        
        let textLayer = CATextLayer()
        textLayer.string = self.text
        textLayer.frame = CGRect(origin: .zero, size: textFrame.size)
        print("textLayer.frame:\(textLayer.frame)")
        textLayer.backgroundColor = UIColor.lightGray.cgColor
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.isWrapped = true
        textLayer.alignmentMode = .left
        // 动态设置 font 大小
        textLayer.font = CGFont(fontName as CFString)
        textLayer.fontSize = fontSize
        
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
        
        animation.duration = CMTimeGetSeconds(self.timeRange.duration)
        
        animation.isRemovedOnCompletion = false
        
        parentLayer.add(animation, forKey: nil)
        
        return parentLayer
    }
    
}
