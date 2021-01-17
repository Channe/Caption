//
//  SubtitleItem.swift
//  Caption
//
//  Created by Qian on 2021/1/14.
//

import UIKit
import AVFoundation
import Speech

class SubtitleItem: NSObject {
    
    private(set) var text: String
    private(set) var timeRange: CMTimeRange

    private(set) var font: UIFont = TTFontB(26)
    
    private(set) var textX: CGFloat = 20
    private(set) var textY: CGFloat = 360
    
    // 仔细设置字幕的 frame，以便播放时和导出时字幕位置一致
    private(set) var textXRate: CGFloat? = nil
    private(set) var textYRate: CGFloat? = nil
    
    static func subtitles(of segments: [SFTranscriptionSegment]?, naturalTimeScale: CMTimeScale) -> [SubtitleItem]? {
        guard let segments = segments else {
            return nil
        }
        // 指定个数单词组成一句字幕
        let segmentsArray = segments.chunked(into: 6)
        
        var subtitleItems: [SubtitleItem]? = nil
        
        segmentsArray.forEach { (segs) in
            let text = segs.reduce("") { $0 + " " + $1.substring }
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
    
    func config(font: UIFont, origin: CGPoint) {
        self.font = font
        self.textX = origin.x
        self.textY = origin.y
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
        //TODO: qianlei 稍微有点偏下
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
        textLayer.backgroundColor = TTBlackColor(0.35).cgColor
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

//let numbers = Array(1...12)
//let result = numbers.chunked(into: 5)
//print(result) // [[1, 2, 3, 4, 5], [6, 7, 8, 9, 10], [11, 12]]
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
