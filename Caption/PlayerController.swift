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
    
    var naturalTimeScale: CMTimeScale {
        return self.asset.tracks(withMediaType: .video).first?.naturalTimeScale ?? 600
    }
    
    private(set) var playerItem: AVPlayerItem
    private var player: AVPlayer
    private(set) var playerView: PlayerView
    
    private(set) var repeats: Bool
    
    private var playerObserver: Any?
    
    deinit {
        print("PlayerController" + #function)
        NotificationCenter.default.removeObserver(self)
        
        if let observer = self.playerObserver {
            self.player.removeTimeObserver(observer)
        }
    }

    private(set) var isVideoMirrored = false
    var progressClosure: ExportVideoProgressClosure? = nil
    
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
                
                self.player.seek(to: CMTime.zero)
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
        
        // 播放器尺寸
        let playerRect = self.playerView.frame
        // 视频的实际播放尺寸
        let videoRect = self.playerView.videoRect
        
        print("playerRect:\(playerRect)")
        print("videoRect:\(videoRect)")

        // 预览时，字幕宽高使用显示控件的宽高；
        self.subtitleItems.forEach { (subtitleItem) in
            let subtitleLayer = subtitleItem.getDisplayLayer(playerSize: playerRect.size, videoPlayRect: videoRect)
            
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
        
        guard let session = VideoTools.buildExportSession(outputURL:URL, asset: self.asset, isVideoMirrored: self.isVideoMirrored, subtitleItems: self.subtitleItems) else {
            print("export video buildExportSession error")
            finish(.failure(.create))
            return
        }
        
        self.session = session
        
        if let progress = self.progressClosure {
            VideoTools.monitorExport(session, progress: progress)
        }
        
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
            print("videoRect:\(self.playerView.videoRect)")

            self.player.play()
        }
        
    }
}
