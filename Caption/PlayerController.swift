//
//  PlayerController.swift
//  Caption
//
//  Created by Qian on 2021/1/11.
//

import UIKit
import AVFoundation

typealias ExportVideoStartClosure = () -> Void

enum ExportError: Error {
    case create
    case url
    case custom(String)
}
typealias ExportVideoFinishClosure = (Result<URL, ExportError>) -> Void

class PlayerController: NSObject {
    
    private let keys = ["tracks","duration","commonMetadata"]

    private var asset: AVAsset
    
    private(set) var playerItem: AVPlayerItem
    private var player: AVPlayer
    private(set) var playerView: PlayerView
    
    private(set) var repeats: Bool
    
    private var playerObserver: Any?
    
    deinit {
        print("PlayerController" + #function)
        NotificationCenter.default.removeObserver(self)
//        self.playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &PlayerItemStatusContext)
        
        if let observer = self.playerObserver {
            self.player.removeTimeObserver(observer)
        }
    }

    private(set) var isVideoMirrored = false
    
    init(URL: URL, repeats: Bool = true, isVideoMirrored: Bool = false) {
        self.asset = AVAsset(url: URL)
        self.repeats = repeats
        self.isVideoMirrored = isVideoMirrored
        
        self.playerItem = AVPlayerItem(asset: self.asset, automaticallyLoadedAssetKeys: self.keys)
        self.player = AVPlayer(playerItem: self.playerItem)
        self.playerView = PlayerView(player: self.player)
        
        super.init()
        
        // 播放视频时打开声音
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
        
        self.prepareToPlay()

        if self.repeats {
            // 循环播放
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { [weak self](note) in
                guard let self = self else { return }
                
                self.player.seek(to: CMTime(seconds: 0, preferredTimescale: 600))
                self.player.play()
            }
        }
    }
    
    private func prepareToPlay() {
        
        self.playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &PlayerItemStatusContext)
        
        // 监听播放进度
        self.playerObserver = self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 2), queue: .main) { (cmTime) in
            print("player time:\(CMTimeGetSeconds(cmTime))")
            
        }
    }
    
    // 播放时增加字幕，处理多段字幕
    private var subtitleItems: [SubtitleItem] = []
    
    func displaySubtitles(_ subtitleItems: [SubtitleItem]) {
        self.subtitleItems = subtitleItems
        
        let playerSize = self.playerView.bounds.size
        
        // 预览时，字幕宽高使用显示控件的宽高；
        self.subtitleItems.forEach { (subtitleItem) in
            let subtitleLayer = subtitleItem
                .getDisplayLayer(displayWidth: playerSize.width,
                                 displayHeight: playerSize.height)
            
            let syncLayer = AVSynchronizedLayer(playerItem: self.playerItem)
            syncLayer.addSublayer(subtitleLayer)
            
            self.playerView.layer.addSublayer(syncLayer)
        }
    }
    
    //MARK: - 导出视频
    
    func exportCancel() {
        self.session?.cancelExport()
    }

    private var session: AVAssetExportSession? = nil

    func exportVideo(URL: URL, finish:@escaping ExportVideoFinishClosure) {
        
        self.session = nil
        
        guard let composition = VideoTools.buildComposition(asset: self.asset) else {
            print("export video buildComposition error")
            finish(.failure(.create))
            return
        }
        
        guard let session = self.buildExportSession(composition) else {
            print("export video buildExportSession error")
            finish(.failure(.create))
            return
        }
        
        session.outputURL = URL
        
        self.session = session
        
        session.exportAsynchronously {
            DispatchQueue.main.async {
                switch session.status {
                case .unknown:
                    print("AVAssetExportSessionStatus Unknown")
                case .waiting:
                    print("AVAssetExportSessionStatus waiting")
                case .exporting:
                    print("AVAssetExportSessionStatus exporting")
                case .completed:
                    print("AVAssetExportSessionStatus completed")
                    finish(.success(URL))
                case .failed:
                    print("AVAssetExportSessionStatus failed")
                    print(session.error as Any)
                    finish(.failure(.custom("failed")))
                case .cancelled:
                    print("AVAssetExportSessionStatus cancelled")
                    finish(.failure(.custom("failed")))
                @unknown default:
                    print("AVAssetExportSessionStatus @unknown default")
                }
            }
        }

    }
    
    private func buildExportSession(_ composition: AVMutableComposition) -> AVAssetExportSession? {
        
        // 不管输入的视频尺寸是多少，转换的视频统一尺寸为 1080p ?
//        let presetName = AVAssetExportPreset1920x1080
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
        
        let naturalVideoComposition = AVMutableVideoComposition(propertiesOf: composition)
        let videoComposition = fixedComposition(naturalVideoComposition, asset: self.asset, orientation: self.asset.videoOrientation)
        if videoComposition.renderSize.width > 0 {
            session.videoComposition = videoComposition
        }

        // 导出时加上字幕
        if self.subtitleItems.count > 0 {
            // 使用旋转之后的宽高
            let renderSize = videoComposition.renderSize
            let bounds = CGRect(origin: .zero, size: renderSize)
            
            let parentLayer = CALayer()
            parentLayer.frame = bounds // 必须和视频尺寸相同
            
            let overlayLayer = CALayer()
            overlayLayer.frame = bounds // 必须和视频尺寸相同
            
            parentLayer.addSublayer(overlayLayer)
            parentLayer.isGeometryFlipped = true // 避免错位现象

            // 处理多段字幕
            self.subtitleItems.forEach { (subtitleItem) in
                let subtitleLayer = subtitleItem
                    .getExportLayer(videoWidth: renderSize.width,
                                    videoHeight: renderSize.height)
                parentLayer.addSublayer(subtitleLayer)
            }
            
            // 将合成的视频帧放在videoLayer中并渲染animationLayer以生成最终帧
            let animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: overlayLayer, in: parentLayer)
            
            videoComposition.animationTool = animationTool
            
            session.videoComposition = videoComposition
        }
        
        return session
    }
    
    private func fixedComposition(_ naturalComposition: AVMutableVideoComposition,asset: AVAsset, orientation: AVCaptureVideoOrientation) -> AVMutableVideoComposition {
        
        let composition = naturalComposition
        
        guard orientation != .landscapeRight else {
            return composition
        }
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return composition
        }
        
        var translateToCenter: CGAffineTransform
        var mixedTransform: CGAffineTransform

        let rotateInstruction = AVMutableVideoCompositionInstruction()
        rotateInstruction.timeRange = CMTimeRange(start: CMTime.zero, duration: asset.duration)
        
        let rotateLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        
        let naturalSize = videoTrack.naturalSize
        
        if orientation == .portrait {
            // 顺时针旋转90°
            translateToCenter = CGAffineTransform(translationX: naturalSize.height, y: 0.0)
            mixedTransform = translateToCenter.rotated(by: CGFloat(Double.pi / 2))
            
            composition.renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
            rotateLayerInstruction.setTransform(mixedTransform, at: CMTime.zero)
        } else if orientation == .landscapeLeft {
            // 顺时针旋转180°
            translateToCenter = CGAffineTransform(translationX: naturalSize.width, y: naturalSize.height)
            mixedTransform = translateToCenter.rotated(by: CGFloat(Double.pi))
            
            composition.renderSize = CGSize(width: naturalSize.width, height: naturalSize.height)
            rotateLayerInstruction.setTransform(mixedTransform, at: CMTime.zero)
        } else if orientation == .portraitUpsideDown {
            // 顺时针旋转270°
            translateToCenter = CGAffineTransform(translationX: 0.0, y: naturalSize.width)
            mixedTransform = translateToCenter.rotated(by: CGFloat((Double.pi / 2) * 3.0))
            
            composition.renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
            rotateLayerInstruction.setTransform(mixedTransform, at: CMTime.zero)
        }
        
        if self.isVideoMirrored {
            // 翻转镜像
            let mirroredTransform = CGAffineTransform(scaleX: -1.0, y: 1.0).rotated(by: CGFloat(Double.pi/2))
            rotateLayerInstruction.setTransform(mirroredTransform, at: CMTime.zero)
            print(" 翻转镜像==========")
        } else {
            print("不翻转镜像==========")
        }
        
        rotateInstruction.layerInstructions = [rotateLayerInstruction]
        composition.instructions = [rotateInstruction]
        
        return composition
    }
    
    
    //MARK: - KVO
    private var PlayerItemStatusContext = 0
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard context == &PlayerItemStatusContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        guard keyPath == #keyPath(AVPlayerItem.status) else {
            return
        }
        
        guard let playerItem = object as? AVPlayerItem else {
            return
        }
        
        DispatchQueue.main.async {
            
            self.playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
            
            guard playerItem.status == .readyToPlay else {
                print(playerItem.error as Any)
                Toast.showTips("Failed to load video.")
                return
            }
            
            self.player.play()
        }
        
    }
}
