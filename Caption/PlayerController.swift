//
//  PlayerController.swift
//  Caption
//
//  Created by Qian on 2021/1/11.
//

import UIKit
import AVFoundation

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
