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
        
        //TODO: qianlei 前置摄像头显示了镜像
        let layer = self.layer as! AVPlayerLayer
        layer.videoGravity = .resizeAspectFill
        
        layer.player = player
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
