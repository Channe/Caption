//
//  AudioCaptionGenerator.swift
//  Caption
//
//  Created by Qian on 2021/1/11.
//

import Foundation
import Speech

typealias CapturenGeneratorStartClosure = () -> Void
typealias CapturenGeneratorFinishClosure = ([[SFTranscriptionSegment]]?) -> Void

class AudioCaptionGenerator: NSObject {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionFileRequest: SFSpeechURLRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
        
    private let videoURL: URL
    
    var finalResult: SFTranscription? = nil
    var finalText: String {
        return self.finalResult?.formattedString ?? ""
    }
    
    var startClosure: CapturenGeneratorStartClosure?
    var finishClosure: CapturenGeneratorFinishClosure?

    init(URL: URL) {
        self.videoURL = URL
        
        super.init()
        
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    break
                case .notDetermined:
                    break
                case .denied, .restricted:
                    Toast.showTips("Please open speech recognizer auth") {
                        SysFunc.openAppSettings()
                    }
                @unknown default:
                    break
                }
            }
        }
        
    }
    
    func start() {
        self.recognitionTask?.cancel()
        self.recognitionTask = nil
                
        guard FileManager.default.fileExists(atPath: self.videoURL.path) else {
            print("no video file.")
            return
        }
        
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = self.recognitionRequest else {
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 在线语音识别效果比离线更好
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        
        let asset = AVAsset(url: self.videoURL)
        AudioSampleDataProvider.loadAudioSampleBuffers(fromAsset: asset) { (buffers) in
            guard let sampleBuffers = buffers else {
                recognitionRequest.endAudio()
                return
            }
            sampleBuffers.forEach({ (sampleBuffer) in
                recognitionRequest.appendAudioSampleBuffer(sampleBuffer)
            })
        }
        
        self.recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { [weak self](result, error) in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                let string = result.bestTranscription.formattedString
                isFinal = result.isFinal
                print("Text --------:")
                print(string)
            }
            
            if error != nil || isFinal {
                print("speech recognizer...")
                print(error?.localizedDescription ?? "speech recognizer is completed.")
                
                if result != nil {
                    self.finalResult = result!.bestTranscription
                }
                
                DispatchQueue.main.async {
                    self.recognitionRequest?.endAudio()
                    self.recognitionTask?.cancel()
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                }
                
            }
            
        })
    }
    
    func startFromFile() {
        self.recognitionTask?.cancel()
        self.recognitionTask = nil
        
        guard FileManager.default.fileExists(atPath: self.videoURL.path) else {
            print("no video file.")
            return
        }
        
        self.recognitionFileRequest = SFSpeechURLRecognitionRequest(url: self.videoURL)
        
        let recognitionRequest = self.recognitionFileRequest!
        
//        recognitionRequest.shouldReportPartialResults = true
        
        // 在线语音识别效果不一定比离线更好
//        if #available(iOS 13, *) {
//            recognitionRequest.requiresOnDeviceRecognition = true
//        }
        
        self.startClosure?()
        
        self.recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { [weak self](result, error) in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
//                let string = result.bestTranscription.formattedString
                isFinal = result.isFinal
//                print("Text --------:")
//                print(string)
            }
            
            if error != nil || isFinal {
                print("speech recognizer...")
                print(error?.localizedDescription ?? "speech recognizer is completed.")
                
                if result != nil {
                    self.finalResult = result!.bestTranscription
                }
                
                DispatchQueue.main.async {
                    self.recognitionTask?.cancel()
                    self.recognitionFileRequest = nil
                    self.recognitionTask = nil
                    
                    // 切分句子
                    if let final = self.finalResult {
                        let subSegmentsArray = self.split(transcription: final)
                        
                        self.finishClosure?(subSegmentsArray)
                    } else {
                        self.finishClosure?(nil)
                    }
                }
            }
            
        })
        
    }
    
    private func split(transcription final: SFTranscription) -> [[SFTranscriptionSegment]]? {
        let averagePauseDuration = final.averagePauseDuration
        let segments = final.segments
        
        var pauseIndexes: [Array<Any>.Index]? = nil
        segments.forEach { (seg) in
            let index = segments.firstIndex(of: seg)!
            if index != 0 {
                let prevIndex = index - 1
                let prevSeg = segments[prevIndex]
                let prevEndTimestamp = prevSeg.timestamp + prevSeg.duration
                let pauseDuration = seg.timestamp - prevEndTimestamp
                // 如果当前单词和前一个单词的间隔大于平均间隔，那么前一个单词之后应该分句
                if pauseDuration > averagePauseDuration {
                    if pauseIndexes == nil {
                        pauseIndexes = []
                    }
                    pauseIndexes?.append(prevIndex)
                }
            }
        }
        
        guard let pauseIndexArray = pauseIndexes else {
            return nil
        }
        
        // 避免字幕太长，应该少于20个单词且大于5个单词
        var separtorIndexes = pauseIndexArray
        for (index, separtor) in pauseIndexArray.enumerated() {
            if index != 0 {
                let prevIndex = index - 1
                let prevSepartor = pauseIndexArray[prevIndex]
                let length = separtor - prevSepartor
                if length < 5 {
                    separtorIndexes.removeAll { $0 == separtor }
                } else if length > 20 {
                    // 给间隔大于20个单词的句子，添加分割点
                    let count: Int = length / 10
                    for times in 1...count {
                        // 直接添加，然后重新排序，因为肯定是递增数组
                        separtorIndexes.append(prevSepartor + times * 10)
                    }
                }
            }
        }
        
        // 重新排序，因为肯定是递增数组
        separtorIndexes.sort(by:<)
        
        // 按照语气停顿处 index 开始断句
        var subSegmentsArray = [[SFTranscriptionSegment]]()
        for _ in 0...separtorIndexes.count {
            subSegmentsArray.append([SFTranscriptionSegment]())
        }
        separtorIndexes.forEach({ (separtor) in
            let index = separtorIndexes.firstIndex(of: separtor)!
            if index == separtorIndexes.count - 1 {
                if separtorIndexes.count == 1 {
                    subSegmentsArray[index] = Array(segments[...separtor])
                    let subSegmentsLast = Array(segments[separtor+1..<segments.count])
                    subSegmentsArray[index+1] = subSegmentsLast
                } else {
                    let prevSpartor = separtorIndexes[index - 1]
                    let subSegments = Array(segments[prevSpartor+1...separtor])
                    subSegmentsArray[index] = subSegments
                    let subSegmentsLast = Array(segments[separtor+1..<segments.count])
                    subSegmentsArray[index+1] = subSegmentsLast
                }
            } else if index == 0 {
                let subSegments = Array(segments[0...separtor])
                subSegmentsArray[index] = subSegments
            } else {
                let prevSpartor = separtorIndexes[index - 1]
                let subSegments = Array(segments[prevSpartor+1...separtor])
                subSegmentsArray[index] = subSegments
            }
        })
        
        return subSegmentsArray
    }
    
}
