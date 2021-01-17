//
//  VideoTools.swift
//  Caption
//
//  Created by Qian on 2021/1/16.
//

import AVFoundation

class VideoTools {
    
    static func buildComposition(asset: AVAsset) -> AVMutableComposition? {
        let composition = AVMutableComposition()
        
        // 音轨轨迹和视频轨迹
        let cursorTime = CMTime.zero
        let sourceAsset = asset
        let timeRange = CMTimeRange(start: cursorTime, duration: sourceAsset.duration)
        
        do {
            let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            let sourceVideoTrack = sourceAsset.tracks(withMediaType: .video).first!
            
            try videoTrack?.insertTimeRange(timeRange, of: sourceVideoTrack, at: cursorTime)
        } catch {
            print("插入合成视频轨迹， 视频有错误")
            return nil
        }
        
        do{
            let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            let sourceAudioTrack = sourceAsset.tracks(withMediaType: .audio).first!
            
            try audioTrack?.insertTimeRange(timeRange, of: sourceAudioTrack, at: cursorTime)
        } catch {
            print("插入合成视频轨迹， 音频有错误")
            return nil
        }
        
        return composition
    }
    
    static func fixed(composition: AVMutableComposition, assetOrientation: AVCaptureVideoOrientation, isVideoMirrored:Bool = false) -> AVMutableVideoComposition {
        
        let videoComposition = AVMutableVideoComposition(propertiesOf: composition)
        
        guard assetOrientation != .landscapeRight else {
            return videoComposition
        }
        
        guard let videoTrack = composition.tracks(withMediaType: .video).first else {
            return videoComposition
        }
        
        var translateToCenter: CGAffineTransform
        var mixedTransform: CGAffineTransform
        
        let rotateInstruction = AVMutableVideoCompositionInstruction()
        rotateInstruction.timeRange = CMTimeRange(start: CMTime.zero, duration: composition.duration)
        
        let rotateLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        
        let naturalSize = videoTrack.naturalSize
        
        if assetOrientation == .portrait {
            // 顺时针旋转90°
            translateToCenter = CGAffineTransform(translationX: naturalSize.height, y: 0.0)
            mixedTransform = translateToCenter.rotated(by: CGFloat(Double.pi / 2))
            
            videoComposition.renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
            rotateLayerInstruction.setTransform(mixedTransform, at: CMTime.zero)
        } else if assetOrientation == .landscapeLeft {
            // 顺时针旋转180°
            translateToCenter = CGAffineTransform(translationX: naturalSize.width, y: naturalSize.height)
            mixedTransform = translateToCenter.rotated(by: CGFloat(Double.pi))
            
            videoComposition.renderSize = CGSize(width: naturalSize.width, height: naturalSize.height)
            rotateLayerInstruction.setTransform(mixedTransform, at: CMTime.zero)
        } else if assetOrientation == .portraitUpsideDown {
            // 顺时针旋转270°
            translateToCenter = CGAffineTransform(translationX: 0.0, y: naturalSize.width)
            mixedTransform = translateToCenter.rotated(by: CGFloat((Double.pi / 2) * 3.0))
            
            videoComposition.renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
            rotateLayerInstruction.setTransform(mixedTransform, at: CMTime.zero)
        }
        
        if isVideoMirrored {
            // 翻转镜像
            let mirroredTransform = CGAffineTransform(scaleX: -1.0, y: 1.0).rotated(by: CGFloat(Double.pi/2))
            rotateLayerInstruction.setTransform(mirroredTransform, at: CMTime.zero)
            print(" 翻转镜像==========")
        } else {
            print("不翻转镜像==========")
        }
        
        rotateInstruction.layerInstructions = [rotateLayerInstruction]
        videoComposition.instructions = [rotateInstruction]
        
        return videoComposition
    }
    
}

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
