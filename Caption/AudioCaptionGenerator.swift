//
//  AudioCaptionGenerator.swift
//  Caption
//
//  Created by Qian on 2021/1/11.
//

import Foundation
import Speech

class AudioCaptionGenerator: NSObject, SFSpeechRecognizerDelegate {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    private let videoURL: URL

    init(URL: URL) {
        self.videoURL = URL
        
        super.init()
        
        self.speechRecognizer.delegate = self
        
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
                case .denied:
                    //TODO: qianlei 跳转 App 设置页面，提示用户打开权限
                    break
                case .restricted:
                    //TODO: qianlei 跳转 App 设置页面，提示用户打开权限
                    break
                @unknown default:
                    break
                }
            }
        }
        
    }
    
    func start() {
        self.recognitionTask?.cancel()
        self.recognitionTask = nil
        
//        let audioSession = AVAudioSession.sharedInstance()
        
        guard FileManager.default.fileExists(atPath: self.videoURL.path) else {
            print("no video file.")
            return
        }
        
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = self.recognitionRequest else {
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
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
            
            recognitionRequest.endAudio()
        }
        
        self.recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if let result = result {
                let string = result.bestTranscription.formattedString
                isFinal = result.isFinal
                print("Text --------:")
                print(string)
            }
            
            if error != nil || isFinal {
                print(error?.localizedDescription ?? "no error")
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
            
        })
    }
    
}
