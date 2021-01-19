//
//  PlayerView.swift
//  Caption
//
//  Created by Qian on 2021/1/11.
//

import UIKit
import AVFoundation

class PlayerView: UIView {

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    init(player: AVPlayer) {
        
        super.init(frame: .zero)
        
        self.backgroundColor = .clear
        
        let layer = self.layer as! AVPlayerLayer
//        layer.videoGravity = .resizeAspectFill
//        layer.videoGravity = .resize
        layer.videoGravity = .resizeAspect
        
        layer.player = player
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var videoRect: CGRect {
        /*
         播放控件 frame:(0.0, 0.0, 414.0, 672.0)
         视频分辨率：340,640
         
         .resize
         videoRect:(2.842170943040401e-14, 0.0, 414.0, 672.0)

         .resizeAspect
         videoRect:(28.5, 0.0, 357.0, 672.0)
         357 / 672 == 0.53125
         
         .resizeAspectFill
         videoRect:(2.842170943040401e-14, 0.0, 414.0, 672.0)
         414 / 672 == 0.616
         
         播放控件 frame:(0.0, 0.0, 414.0, 672.0)
         视频分辨率：853,480
         .resize
         videoRect:(0.0, 0.0, 414.0, 672.0)
         
         .resizeAspect
         videoRect:(0.0, 219.51699882766707, 414.0, 232.9660023446659)

         */
        let layer = self.layer as! AVPlayerLayer
        return layer.videoRect
    }
    
}
