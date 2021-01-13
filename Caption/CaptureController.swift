//
//  CaptureController.swift
//  Caption
//
//  Created by Qian on 2021/1/13.
//

import UIKit
import AVFoundation

class CaptureController {
    
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        
        return session
    }()
    
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        layer.videoGravity = .resizeAspectFill
        
        return layer
    }()
    
    private let videoQueue = DispatchQueue.global(qos: .default)
    
    private let movieOutput = AVCaptureMovieFileOutput()
    private var activeInput: AVCaptureDeviceInput? = nil
    
    init(inView view: UIView) {
        
        setupSession()
        
        self.previewLayer.frame = view.bounds
        view.layer.insertSublayer(self.previewLayer, at: 0)
    }
    
    private func setupSession() {
        
        let camera = AVCaptureDevice.default(for: .video)
        /*
         前置摄像头
         */
        
        do {
            let input = try AVCaptureDeviceInput(device: camera!)
            if captureSession.canAddInput(input){
                captureSession.addInput(input)
                
                self.activeInput = input
                // 添加拍照， 录像的输入
            }
        } catch {
            print("Error settings device input: \(error)")
            
        }
        
        // 设置麦克风
        let microphone = AVCaptureDevice.default(for: .audio)
        do{
            let micInput = try AVCaptureDeviceInput(device: microphone!)
            if captureSession.canAddInput(micInput){
                captureSession.addInput(micInput)
                //   添加麦克风的输入
            }
        } catch {
            print("Error setting device audio input: \(String(describing: error.localizedDescription))")
        }
        
        if captureSession.canAddOutput(movieOutput){
            captureSession.addOutput(movieOutput)
        }
        
    }
    
    func startSession() {
        if !self.captureSession.isRunning {
            videoQueue.async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func switchCamera() {
        guard !self.movieOutput.isRecording else {
            return
        }
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let activeInput = self.activeInput else {
            return
        }
        
        do {
            var input: AVCaptureDeviceInput!
            if activeInput.device == frontCamera {
                input = try AVCaptureDeviceInput(device: backCamera)
            } else {
                input = try AVCaptureDeviceInput(device: frontCamera)
            }
            
            self.captureSession.beginConfiguration()
            self.captureSession.removeInput(activeInput)
            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
                self.activeInput = input
            }
            
            self.captureSession.commitConfiguration()
        } catch {
            print("Error , switching cameras: \(String(describing: error))")
        }
    }
    
}
