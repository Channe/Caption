//
//  AVAssetExtension.swift
//  Pods
//
//  Created by Qian on 2021/1/15.
//

import AVFoundation

extension AVAsset {
    
    var videoOrientation: AVCaptureVideoOrientation {
        guard let videoTrack = self.tracks(withMediaType: .video).first else {
            return .landscapeRight
        }
        
        let t = videoTrack.preferredTransform
        
        if (t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) || (t.a == 0 && t.b == 1.0 && t.c == 1.0 && t.d == 0) {
            return .portrait // 90
        } else if (t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0) || (t.a == 0 && t.b == -1.0 && t.c == -1.0 && t.d == 0) {
            return .portraitUpsideDown // 270
        } else if t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0 {
            return .landscapeRight // 0
        } else if t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0 {
            return .landscapeLeft // 180
        } else {
            return .landscapeRight
        }
    }
    
}
