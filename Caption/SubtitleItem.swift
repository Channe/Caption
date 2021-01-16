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
    
    init(text: String, timestamp:TimeInterval, duration: TimeInterval, font: UIFont) {
        
        self.text = text
        self.timeRange = CMTimeRange(start: CMTime(seconds: timestamp, preferredTimescale: 600),
                                     duration: CMTime(seconds: duration, preferredTimescale: 600))
        self.font = font
        
        super.init()
        
    }
    
    func buildLayer(frame: CGRect) -> CALayer {
        // 需要在这里设置字幕的 frame，以便播放时和导出时字幕位置一致

        let parentLayer = CALayer()
        parentLayer.frame = frame
//        parentLayer.contentsScale = UIScreen.main.scale

        let textLayer = CATextLayer()
        textLayer.string = self.text
        textLayer.frame = CGRect(origin: .zero, size: frame.size)
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
        
        // fadeinfadeout
        let animation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.opacity))
        
        // 淡入：从透明到不透明，淡出：再从不透明到透明
        animation.values = [0.0, 1.0, 1.0, 0.0]
        // 每段动画执行的时间点，20%的时间淡入，20%的时间淡出
        animation.keyTimes = [0.0, 0.2, 0.8, 1.0]
        
        //TODO: qianlei animation.beginTime
        // 设置起始时间，如果要表示影片片头，不能用 0.0 来赋值 beginTime，因为 CoreAnimation 会将 0.0 的 beginTime 转为 CACurrentMediaTime()，所以要用 AVCoreAnimationBeginTimeAtZero 来代替
//        animation.beginTime = CMTimeGetSeconds(self.timeRange.start)
        animation.beginTime = CMTimeGetSeconds(CMTime(seconds: 1, preferredTimescale: 1))
        
        animation.duration = CMTimeGetSeconds(self.timeRange.duration)
        
        animation.isRemovedOnCompletion = false
        
        parentLayer.add(animation, forKey: nil)
        
        return parentLayer
    }
    
    
}
