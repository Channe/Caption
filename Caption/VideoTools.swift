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
    
}
