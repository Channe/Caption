//
//  VideoTools.swift
//  Caption
//
//  Created by Qian on 2021/1/16.
//

import AVFoundation

enum ExportResult {
    case finish
    case progress(Float)
}

typealias ExportVideoProgressClosure = (ExportResult) -> Void

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
    
    static func buildExportSession(outputURL: URL, composition: AVMutableComposition, asset: AVAsset, isVideoMirrored:Bool = false, subtitleItems: [SubtitleItem]? = nil) -> AVAssetExportSession? {
        
        let presetName = AVAssetExportPresetHighestQuality
        
        let presets = AVAssetExportSession.exportPresets(compatibleWith: composition)
        guard presets.contains(presetName) else {
            print("AVAssetExportSession cannot support \(presetName)")
            return nil
        }
        guard let session = AVAssetExportSession(asset: composition, presetName: presetName) else {
            print("AVAssetExportSession error")
            return nil
        }
        session.shouldOptimizeForNetworkUse = true
        
        if session.supportedFileTypes.contains(.mp4) {
            session.outputFileType = .mp4
        } else {
            session.outputFileType = session.supportedFileTypes.first!
        }
        
        let videoComposition = VideoTools.fixed(composition: composition,
                                                assetOrientation: asset.videoOrientation,
                                                isVideoMirrored: isVideoMirrored)
        if videoComposition.renderSize.width > 0 {
            session.videoComposition = videoComposition
        }
        
        // 导出时加上字幕
        if let subtitles = subtitleItems, subtitles.count > 0 {
            // 使用旋转之后的宽高
            let renderSize = videoComposition.renderSize
            let bounds = CGRect(origin: .zero, size: renderSize)
            
            let parentLayer = CALayer()
            parentLayer.frame = bounds // 必须和视频尺寸相同
            
            let overlayLayer = CALayer()
            overlayLayer.frame = bounds // 必须和视频尺寸相同
            
            parentLayer.addSublayer(overlayLayer)
            parentLayer.isGeometryFlipped = true // 避免错位现象
            
            let subtitleService = SubtitleService()

            // 处理多段字幕
            subtitles.forEach { (subtitleItem) in
                let subtitleLayer = subtitleService.getExportLayer(item:subtitleItem, videoRenderSize: renderSize)
                
                parentLayer.addSublayer(subtitleLayer)
            }
            
            // 将合成的视频帧放在videoLayer中并渲染animationLayer以生成最终帧
            let animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: overlayLayer, in: parentLayer)
            
            videoComposition.animationTool = animationTool
            
            session.videoComposition = videoComposition
        }
        
        session.outputURL = outputURL
        
        return session
    }
    
    static func buildExportSession(outputURL: URL, asset: AVAsset, isVideoMirrored:Bool = false, subtitleItems: [SubtitleItem]? = nil) -> AVAssetExportSession? {
        
        guard asset.isExportable else {
            print("cannot export,asset")
            return nil
        }
        
        guard let composition = VideoTools.buildComposition(asset: asset) else {
            print("export video buildComposition error")
            return nil
        }
        
        guard let session = VideoTools.buildExportSession(outputURL: outputURL, composition:composition, asset: asset, isVideoMirrored: isVideoMirrored, subtitleItems: subtitleItems) else {
            print("export video buildExportSession error")
            return nil
        }
        
        return session
    }
    
    static func monitorExport(_ session: AVAssetExportSession, progress:@escaping ExportVideoProgressClosure) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let status = session.status
            if status == .exporting {
                print("exporting progress:\(session.progress)")
                progress(.progress(session.progress))
                self.monitorExport(session, progress: progress)
            } else {
                progress(.finish)
            }
        }
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
