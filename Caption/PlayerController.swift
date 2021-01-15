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
        NotificationCenter.default.removeObserver(self)
//        self.playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &PlayerItemStatusContext)
        
        if let observer = self.playerObserver {
            self.player.removeTimeObserver(observer)
        }
    }

    init(URL: URL, repeats: Bool = true) {
        self.asset = AVAsset(url: URL)
        self.repeats = repeats
        
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
    
    private var subtitleLayer: CALayer? = nil
    func displaySubtitle(_ text: String) {
        let font = TTFontB(26)
        
        let playerSize = self.playerView.bounds.size
        // 字幕宽度固定，高度根据字体动态计算
        let textWidth = playerSize.width - 20*2
        let textHeight = text.height(withConstrainedWidth: textWidth, font: font)
        let size = CGSize(width: textWidth, height: textHeight)
        
        //TODO: Qianlei 字幕时间
        let subtitleItem = SubtitleItem(text: text, timestamp: 0, duration: 5, size: size, font: font)
        
        self.subtitleLayer = subtitleItem.buildLayer()
        
        let syncLayer = AVSynchronizedLayer(playerItem: self.playerItem)
        syncLayer.addSublayer(self.subtitleLayer!)
        // 字幕位置
        syncLayer.frame = CGRect(x: 20, y: 400, width: textWidth, height: textHeight)
        
        self.playerView.layer.addSublayer(syncLayer)
        
    }
    
    //MARK: - 导出视频
    
    func exportCancel() {
        self.session?.cancelExport()
    }

    private lazy var composition = AVMutableComposition()
    private var session: AVAssetExportSession? = nil

    func exportVideo(URL: URL, finish:@escaping ExportVideoFinishClosure) {
        
        self.session = nil
        
        // 音轨轨迹和视频轨迹
        let cursorTime = CMTime.zero
        let sourceAsset = self.asset
        let timeRange = CMTimeRange(start: cursorTime, duration: sourceAsset.duration)
        
        do {
            let videoTrack = self.composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            let sourceVideoTrack = sourceAsset.tracks(withMediaType: .video).first!
            
            try videoTrack?.insertTimeRange(timeRange, of: sourceVideoTrack, at: cursorTime)
        } catch {
            print("插入合成视频轨迹， 视频有错误")
            finish(.failure(.create))
        }
        
        do{
            let audioTrack = self.composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            let sourceAudioTrack = sourceAsset.tracks(withMediaType: .audio).first!
            
            try audioTrack?.insertTimeRange(timeRange, of: sourceAudioTrack, at: cursorTime)
        } catch {
            print("插入合成视频轨迹， 音频有错误")
            finish(.failure(.create))
        }
        
        guard let session = self.makeExportable() else {
            print("export video makeExportable error")
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
    
    private func makeExportable() -> AVAssetExportSession? {
        
        let presetName = AVAssetExportPresetHighestQuality
        
        let presets = AVAssetExportSession.exportPresets(compatibleWith: self.composition)
        guard presets.contains(presetName) else {
            print("AVAssetExportSession cannot support \(presetName)")
            return nil
        }
        guard let session = AVAssetExportSession(asset: self.composition, presetName: presetName) else {
            print("AVAssetExportSession error")
            return nil
        }
        session.shouldOptimizeForNetworkUse = true
        
        if session.supportedFileTypes.contains(.mp4) {
            session.outputFileType = .mp4
        } else {
            session.outputFileType = session.supportedFileTypes.first!
        }
        
        var videoComposition = AVMutableVideoComposition(propertiesOf: self.composition)
//        videoComposition.renderSize = CGSize(width: 320, height: 568)
        videoComposition = fixedComposition(composition: videoComposition, orientation: self.asset.videoOrientation)

        // 导出时带上字幕
        if let subtitleLayer = self.subtitleLayer {
            let animationLayer = CALayer()
            animationLayer.frame = self.playerView.bounds
            
            let videoPlayer = CALayer()
            videoPlayer.frame = self.playerView.bounds
            
            animationLayer.addSublayer(videoPlayer)
            animationLayer.addSublayer(subtitleLayer)
            
            animationLayer.isGeometryFlipped = true // 避免错位现象
            
            let animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoPlayer, in: animationLayer)
            
            videoComposition.animationTool = animationTool
            
            session.videoComposition = videoComposition
        }
        
        return session
    }
    
    private func fixedComposition(composition: AVMutableVideoComposition, orientation: AVCaptureVideoOrientation) -> AVMutableVideoComposition {
        guard orientation != .landscapeRight else {
            return composition
        }
        
        guard let videoTrack = self.asset.tracks(withMediaType: .video).first else {
            return composition
        }
        
        var translateToCenter: CGAffineTransform
        var mixedTransform: CGAffineTransform

        let rotateInstruction = AVMutableVideoCompositionInstruction()
        rotateInstruction.timeRange = CMTimeRange(start: CMTime.zero, duration: self.asset.duration)
        
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
