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
    
    var textXRate: CGFloat? = nil
    var textYRate: CGFloat? = nil
    var textWHRate: CGFloat? = nil
    var fontRate: CGFloat? = nil
    
    init(text: String, timestamp:TimeInterval, duration: TimeInterval, naturalTimeScale: CMTimeScale) {
        
        self.text = text
        self.timeRange = CMTimeRange(start: CMTime(seconds: timestamp, preferredTimescale: naturalTimeScale),
                                     duration: CMTime(seconds: duration, preferredTimescale: naturalTimeScale))
        super.init()
    }
    
    private(set) var style = SubtitleStyle()
    
    @discardableResult
    func config(style: SubtitleStyle) -> Self {
        self.style = style
        return self
    }
    
}
