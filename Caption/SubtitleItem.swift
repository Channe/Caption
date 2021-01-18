//
//  SubtitleItem.swift
//  Caption
//
//  Created by Qian on 2021/1/14.
//

import UIKit
import AVFoundation
import Speech

struct SubtitleStyle {
    
    var font: UIFont = TTFontB(26)
    var leftMargin: CGFloat = 20
    var bottomMargin: CGFloat = 300
    var textColor: UIColor = .white
    var backgroundColor: UIColor = TTBlackColor(0.35)
    var alignment: CATextLayerAlignmentMode = .left
    
}

class SubtitleItem: NSObject {
    
    private(set) var text: String
    private(set) var timeRange: CMTimeRange
    
    private(set) var textX: CGFloat = 20
    private(set) var textY: CGFloat = 360
    private(set) var textXRate: CGFloat? = nil
    private(set) var textYRate: CGFloat? = nil
    private(set) var textWHRate: CGFloat? = nil
    private(set) var fontRate: CGFloat? = nil
    
    static func subtitles(segmentsArray: [[SFTranscriptionSegment]]?, naturalTimeScale: CMTimeScale) -> [SubtitleItem]? {
        guard let segmentsArray = segmentsArray else {
            return nil
        }
        var subtitleItems: [SubtitleItem]? = nil
        
        segmentsArray.forEach { (segs) in
            guard segs.count > 0 else {
                return
            }
            let text = segs.reduce("") { $0 + $1.substring + " " }
            let startTimestamp = segs.first!.timestamp
            let endTimestamp = segs.last!.timestamp + segs.last!.duration
            let duration = endTimestamp - startTimestamp
            
            if subtitleItems == nil {
                subtitleItems = []
            }
            subtitleItems?.append(SubtitleItem(text: text, timestamp: startTimestamp, duration: duration, naturalTimeScale:naturalTimeScale))
        }
        
        return subtitleItems
    }
    
    init(text: String, timestamp:TimeInterval, duration: TimeInterval, naturalTimeScale: CMTimeScale) {
        
        self.text = text
        self.timeRange = CMTimeRange(start: CMTime(seconds: timestamp, preferredTimescale: naturalTimeScale),
                                     duration: CMTime(seconds: duration, preferredTimescale: naturalTimeScale))
        super.init()
    }
    
//    @discardableResult
//    func config(font: UIFont, leftMargin: CGFloat, bottomMargin: CGFloat) -> Self {
//        self.font = font
//        self.leftMargin = leftMargin
//        self.bottomMargin = bottomMargin
//
//        return self
//    }
    
    private(set) var style = SubtitleStyle()
    
    @discardableResult
    func config(style: SubtitleStyle) -> Self {
        self.style = style
        return self
    }
    
    //MARK: - CATextLayer

    /*
     字幕大小取决于三种尺寸：控件宽高，视频在控件上缩放之后的宽高，视频本身宽高
     预览时，字幕宽高使用显示控件的宽高；
     导出时，字幕宽高使用视频本身的宽高；
     */
    // 预览时，字幕宽高使用显示控件的宽高；
    func getDisplayLayer(displayWidth: CGFloat, displayHeight: CGFloat) -> CALayer {
        print(#function)
                
        let font = self.style.font
        
        // 字幕宽度固定，高度根据字体动态计算
        let textWidth = displayWidth - textX * 2
        let textHeight = self.text.height(withConstrainedWidth: textWidth, font: font)
        self.textWHRate = textWidth / textHeight
        
        self.textX = self.style.leftMargin
        self.textY = displayHeight - self.style.bottomMargin - textHeight
        self.textXRate = self.textX / displayWidth
        self.textYRate = self.textY / displayHeight

        let textFrame = CGRect(x: textX, y: textY, width: textWidth, height: textHeight)

        self.fontRate = self.style.font.pointSize / textWidth
        
        return buildLayer(textFrame: textFrame, fontName: font.fontName, fontSize: font.pointSize)
    }
    
    // 导出时，字幕宽高使用视频本身的宽高；
    func getExportLayer(videoWidth: CGFloat, videoHeight: CGFloat) -> CALayer {
        print(#function)
        
        let font = self.style.font

        let textX = videoWidth * self.textXRate!
        //TODO: qianlei 稍微有点偏下
        let textY = videoHeight * self.textYRate!
        
        let textWidth = videoWidth - textX * 2
        let textHeight = textWidth / self.textWHRate!
        let textFrame = CGRect(x: textX, y: textY, width: textWidth, height: textHeight)

        let fontSize = textWidth * self.fontRate!
        
        return buildLayer(textFrame: textFrame, fontName: font.fontName, fontSize: fontSize)
    }
    
    private func buildLayer(textFrame:CGRect, fontName: String, fontSize: CGFloat) -> CALayer {
        print("buildLayer textFrame:\(textFrame)")
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

        textLayer.contentsScale = UIScreen.main.scale
        textLayer.isWrapped = true

        textLayer.foregroundColor = self.style.textColor.cgColor
        textLayer.backgroundColor = self.style.backgroundColor.cgColor

        textLayer.alignmentMode = self.style.alignment
        
        // 动态设置 font 大小
        textLayer.font = CGFont(fontName as CFString)
        textLayer.fontSize = fontSize
        
        parentLayer.addSublayer(textLayer)
        
        // fadeinfadeout
        let animation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.opacity))
        
        // 淡入：从透明到不透明，淡出：再从不透明到透明
        animation.values = [0.0, 1.0, 1.0, 0.0]
        // 每段动画执行的时间点，10%的时间淡入，10%的时间淡出
        animation.keyTimes = [0.0, 0.1, 0.9, 1.0]
        
        // 设置起始时间，如果要表示影片片头，不能用 0.0 来赋值 beginTime，因为 CoreAnimation 会将 0.0 的 beginTime 转为 CACurrentMediaTime()，所以要用 AVCoreAnimationBeginTimeAtZero 来代替
        var start = CMTimeGetSeconds(self.timeRange.start)
        if start == 0.0 {
            start = AVCoreAnimationBeginTimeAtZero
        }
        animation.beginTime = start
        animation.duration = CMTimeGetSeconds(self.timeRange.duration)
        print("animation.beginTime:\(animation.beginTime), animation.duration:\(animation.duration)")
        
        animation.isRemovedOnCompletion = false
        
        parentLayer.add(animation, forKey: "opacity")
        
        return parentLayer
    }
    
}
