//
//  SubtitleService.swift
//  Caption
//
//  Created by Qian on 2021/1/21.
//

import UIKit
import AVFoundation
import Speech

struct SubtitleStyle {
    
    var font: UIFont = TTFontB(26)
    /// 字幕和视频左边的边距
    var leftMargin: CGFloat = 20
    /// 字幕和视频底边的边距
    var bottomMargin: CGFloat = 20
    var textColor: UIColor = .white
    var backgroundColor: UIColor = TTBlackColor(0.35)
    var alignment: CATextLayerAlignmentMode = .left
    
}

class SubtitleService {
    
    /*
     每条字幕对应一个 SubtitleItem
     所有字幕使用同一个 CATextLayer
     目前所有字幕使用同一个样式 SubtitleStyle，但未来不一定
     */
    
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
        
//        return [SubtitleItem(text: "subtitleItems?.append(SubtitleItem(text: text, timestamp: startTimestamp, duration: duration, naturalTimeScale:naturalTimeScale))", timestamp: 0, duration: 60, naturalTimeScale: 300)]
    }
    
    //MARK: - CATextLayer
    
    /*
     字幕大小取决于三种尺寸：控件宽高，视频在控件上缩放之后的宽高（视频显示宽高），视频本身宽高
     预览时，字幕宽高使用视频显示的宽高；
     导出时，字幕宽高使用视频本身的宽高；
     */
    // 预览时，字幕宽高使用视频显示的宽高；
    func getDisplayLayer(item: SubtitleItem, playerSize: CGSize, videoPlayRect: CGRect) -> CALayer {
        
        let displayWidth = videoPlayRect.width
        
        let font = item.style.font
        
        // 字幕宽度
        let textWidth = displayWidth - item.style.leftMargin * 2
        // 字幕宽度固定，高度根据字体动态计算
        let textHeight = item.text.height(withConstrainedWidth: textWidth, font: font)
        // 字幕宽高比
        item.textWHRate = textWidth / textHeight
        // 字体比例
        item.fontRate = item.style.font.pointSize / textWidth
        
        // 计算字幕在视频控件上的 x
        let textX = videoPlayRect.minX + item.style.leftMargin
        // 计算字幕在视频控件上的 x
        let textY = videoPlayRect.maxY - item.style.bottomMargin - textHeight
        // 字幕 x 位置比例
        item.textXRate = item.style.leftMargin / displayWidth
        // 字幕 y 位置比例
        item.textYRate = (textY - videoPlayRect.minY) / videoPlayRect.size.height
        
        let textFrame = CGRect(x: textX, y: textY, width: textWidth, height: textHeight)
        
        return buildLayer(item:item, textFrame: textFrame, fontName: font.fontName, fontSize: font.pointSize)
    }
    
    // 导出时，字幕宽高使用视频本身的宽高；
    func getExportLayer(item: SubtitleItem, videoRenderSize: CGSize) -> CALayer {
        
        let videoWidth = videoRenderSize.width
        let videoHeight = videoRenderSize.height
        
        let textX = videoWidth * item.textXRate!
        //TODO: qianlei 稍微有点偏下
        let textY = videoHeight * item.textYRate!
        
        let textWidth = videoWidth - textX * 2
        let textHeight = textWidth / item.textWHRate!
        let textFrame = CGRect(x: textX, y: textY, width: textWidth, height: textHeight)
        
        let font = item.style.font
        let fontSize = textWidth * item.fontRate!
        
        return buildLayer(item:item, textFrame: textFrame, fontName: font.fontName, fontSize: fontSize)
    }
    
    private func buildLayer(item: SubtitleItem, textFrame:CGRect, fontName: String, fontSize: CGFloat) -> CALayer {
//        print("buildLayer textFrame:\(textFrame)")
//        print("buildLayer fontSize:\(fontSize)")
        
        let parentLayer = CALayer()
        parentLayer.frame = textFrame
        // 默认隐藏，通过淡入动画来显示
        parentLayer.opacity = 0.0
        
        let textLayer = CATextLayer()
        textLayer.string = item.text
        textLayer.frame = CGRect(origin: .zero, size: textFrame.size)
        
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.isWrapped = true
        
        textLayer.foregroundColor = item.style.textColor.cgColor
        textLayer.backgroundColor = item.style.backgroundColor.cgColor
        
        textLayer.alignmentMode = item.style.alignment
        
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
        var start = CMTimeGetSeconds(item.timeRange.start)
        if start == 0.0 {
            start = AVCoreAnimationBeginTimeAtZero
        }
        animation.beginTime = start
        animation.duration = CMTimeGetSeconds(item.timeRange.duration)
        
        animation.isRemovedOnCompletion = false
        
        parentLayer.add(animation, forKey: "opacity")
        
        return parentLayer
    }
    
}
