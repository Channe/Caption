//
//  PlayerController.swift
//  Caption
//
//  Created by Qian on 2021/1/11.
//

import UIKit
import AVFoundation

class PlayerController: NSObject {
    
    private var asset: AVAsset
    private var playerItem: AVPlayerItem
    private var player: AVPlayer
    private(set) var playerView: PlayerView
    
    init(URL: URL) {
        self.asset = AVAsset(url: URL)
        
        let keys = ["tracks","duration","commonMetadata"]
//        let keys = ["playable", "hasProtectedContent"]
        
        self.playerItem = AVPlayerItem(asset: self.asset, automaticallyLoadedAssetKeys: keys)
        self.player = AVPlayer(playerItem: playerItem)
        self.playerView = PlayerView(player: self.player)
        
        super.init()
        
        prepareToPlay()
    }
    
    private func prepareToPlay() {
        
        self.playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &PlayerItemStatusContext)
        
        // 播放视频时打开声音
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
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
            
            // 此时可以开始播放
//                let duration = self.playerItem.duration
            
            self.player.play()
        }
        
    }
}
