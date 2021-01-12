//
//  AudioSampleDataProvider.swift
//  Caption
//
//  Created by Qian on 2021/1/11.
//

import Foundation
import AVFoundation

typealias SampleDataComletionClosure = (NSData?) -> Void
typealias SampleBufferComletionClosure = ([CMSampleBuffer]?) -> Void

class AudioSampleDataProvider {
    
    func loadAudioSamples(fromAsset asset: AVAsset, completion: @escaping SampleDataComletionClosure) {
        
        let tracks = "tracks"
        
        asset.loadValuesAsynchronously(forKeys: [tracks]) {
            
            let status = asset.statusOfValue(forKey: tracks, error: nil)
            var sampleData: NSData? = nil
            
            if status == .loaded {
                sampleData = self.readAudioSamples(fromAsset: asset)
            }
            
            DispatchQueue.main.async {
                completion(sampleData)
            }
        }
        
    }
    
    private func readAudioSamples(fromAsset asset: AVAsset) -> NSData? {

        guard let assetReader = try? AVAssetReader(asset: asset) else {
            print("Error creating asset reader")
            return nil
        }

        //获取资源中第一个音频轨道（最好是根据需求的媒体类型来获取轨道）
        guard let track = asset.tracks(withMediaType: .audio).first else {
            print("No audio track found in asset")
            return nil
        }
        
        //从资源轨道读取音频样本时使用的解压设置
        //样本需要以未被压缩的格式读取(kAudioFormatLinearPCM)
        //样本以16位的little-endian字节顺序的有符号整型方式读取
        let outputSettings: [String : Any] = [
            AVFormatIDKey:Int(kAudioFormatLinearPCM),
            AVLinearPCMIsBigEndianKey:false,
            AVLinearPCMIsFloatKey:false,
            AVLinearPCMBitDepthKey:16
        ]
        
        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        assetReader.add(trackOutput)
        assetReader.startReading()
        
        let sampleData = NSMutableData()
        
        while assetReader.status == .reading {
            // 迭代返回包含一个音频样本的CMSampleBuffer
            autoreleasepool {
                if let sampleBuffer = trackOutput.copyNextSampleBuffer() {
                    //7. CMSampleBuffer的音频样本被包含在一个CMBlockBuffer类型中
                    if let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                        //8. 获取blockBuffer数据长度
                        let length = CMBlockBufferGetDataLength(blockBuffer)
                        //9. 拼接sampleData
                        let sampleBytes = UnsafeMutablePointer<Int16>.allocate(capacity: length)
                        CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: sampleBytes)
                        sampleData.append(sampleBytes, length: length)
                    }
                }
            }
        }
        
        // 读取成功,返回数据
        if assetReader.status == .completed {
            return sampleData
        } else {
            print("Failed to read audio samples from asset.")
            return nil
        }
    }
    
    //MARK: -
    
    class func loadAudioSampleBuffers(fromAsset asset: AVAsset, completion: @escaping SampleBufferComletionClosure) {

        let tracks = "tracks"

        asset.loadValuesAsynchronously(forKeys: [tracks]) {

            let status = asset.statusOfValue(forKey: tracks, error: nil)
            var sampleBuffers: [CMSampleBuffer]? = nil

            if status == .loaded {
                sampleBuffers = self.readAudioSampleBuffers(fromAsset: asset)
            }

            DispatchQueue.main.async {
                print("sampleBuffers.count:\(sampleBuffers?.count ?? 0)")
                completion(sampleBuffers)
            }
        }

    }
    
    private class func readAudioSampleBuffers(fromAsset asset: AVAsset) -> [CMSampleBuffer]? {

        do {
            let assetReader = try AVAssetReader(asset: asset)
            
            //获取资源中第一个音频轨道（最好是根据需求的媒体类型来获取轨道）
            guard let track = asset.tracks(withMediaType: .audio).first else {
                print("No audio track found in asset")
                return nil
            }
            
            //从资源轨道读取音频样本时使用的解压设置
            //样本需要以未被压缩的格式读取(kAudioFormatLinearPCM)
            //样本以16位的little-endian字节顺序的有符号整型方式读取
            let outputSettings: [String : Any] = [
                AVFormatIDKey:Int(kAudioFormatLinearPCM),
                AVLinearPCMIsBigEndianKey:false,
                AVLinearPCMIsFloatKey:false,
                AVLinearPCMBitDepthKey:16
            ]
            
            let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
            assetReader.add(trackOutput)
            assetReader.startReading()
            
            var sampleBuffers = [CMSampleBuffer]()
            
            while assetReader.status == .reading {
                // 迭代返回包含一个音频样本的CMSampleBuffer
                if let sampleBuffer = trackOutput.copyNextSampleBuffer() {
                    sampleBuffers.append(sampleBuffer)
                }
            }
            
            // 读取成功,返回数据
            if assetReader.status == .completed {
                return sampleBuffers
            } else {
                print("Failed to read audio samples from asset.")
                return nil
            }
            
        } catch {
            print("Error creating asset reader")
            print(error)
            return nil
        }
    }
    
}
