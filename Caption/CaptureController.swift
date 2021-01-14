//
//  CaptureController.swift
//  Caption
//
//  Created by Qian on 2021/1/13.
//

import UIKit
import AVFoundation

typealias CaptureMovieStartClosure = () -> Void
typealias CaptureMovieRecordingClosure = (TimeInterval) -> Void
typealias CaptureMovieFinishClosure = (URL) -> Void

class CaptureController: NSObject {
    
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
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
    
    private weak var previewView: UIView?
    private var outputURL:URL
    
    private var timer: Timer?
    private var duration: TimeInterval = 0
    
    var startClosure: CaptureMovieStartClosure? = nil
    var recordingClosure: CaptureMovieRecordingClosure? = nil
    var finishClosure: CaptureMovieFinishClosure? = nil

    init(inView view: UIView, saveToURL: URL) {
        
        self.previewView = view
        self.outputURL = saveToURL
        
        super.init()
        
        let tap = UITapGestureRecognizer(target: self , action: #selector(tapToFocusAction))
        view.addGestureRecognizer(tap)
        
        setupSession()
        
        self.previewLayer.frame = view.bounds
        view.layer.insertSublayer(self.previewLayer, at: 0)
    }
    
    private func setupSession() {
        
        // 默认是前置摄像头
        //TODO: qianlei 预览和实际拍摄的画面有差异
        let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        
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
    
    @objc private func tapToFocusAction(gesture: UIGestureRecognizer) {
        guard let device = self.activeInput?.device,
              device.isFocusPointOfInterestSupported else {
            return
        }
        
        let point = gesture.location(in: self.previewView)
        let poi = self.previewLayer.captureDevicePointConverted(fromLayerPoint: point)
        
        focusAtPoint(poi)
    }
    
    private func focusAtPoint(_ point: CGPoint) {
        guard let device = self.activeInput?.device,
              device.isFocusPointOfInterestSupported,
              device.isFocusModeSupported(.autoFocus) else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            device.focusPointOfInterest = point
            device.focusMode = .autoFocus
            device.unlockForConfiguration()
        } catch {
            print("Error focusing on POI: \(String(describing: error.localizedDescription))")
        }
    }
    
    var isFlashOpened: Bool = false
    var isFlashEnable: Bool {
        get {
            return self.activeInput?.device.isFlashAvailable ?? false
        }
    }
    
    func openFlash(yesOrNo: Bool) {
        //TODO: qianlei 打开闪光灯，记录闪光灯状态
        
        guard let device = self.activeInput?.device else {
            return
        }
        
        guard device.isFlashAvailable else {
            isFlashOpened = false
            return
        }
        
        Toast.showTips("to do")
        
    }
    
}

extension CaptureController: AVCaptureFileOutputRecordingDelegate {
    
    func startReordingMovie() {
        guard self.movieOutput.isRecording == false else {
            print("movieOutput.isRecording")
            stopRecordingMovie()
            return
        }
        guard let device = self.activeInput?.device else {
            return
        }
        guard let connection = self.movieOutput.connection(with: .video) else {
            return
        }
        
        if connection.isVideoOrientationSupported {
            // 获取设备方向
            connection.videoOrientation = AVCaptureVideoOrientation(ui:UIDevice.current.orientation)
        }
        
        if connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
        }
        
        if connection.isVideoMirroringSupported {
            // 只有前置摄像头需要镜像
            if device.position == .front {
                connection.isVideoMirrored = true
            } else {
                connection.isVideoMirrored = false
            }
        }
        
        if device.isSmoothAutoFocusSupported {
            do {
                try device.lockForConfiguration()
                device.isSmoothAutoFocusEnabled = false
                device.unlockForConfiguration()
            } catch {
                print("Error setting configuration: \(String(describing: error.localizedDescription))")
            }
        }
        
        if FileManager.default.fileExists(atPath: self.outputURL.path) {
            do {
                try FileManager.default.removeItem(at: self.outputURL)
            } catch {
                print("Delete exist file error:\(self.outputURL)")
            }
        }
        
        self.movieOutput.startRecording(to: self.outputURL, recordingDelegate: self)
    }
    
    func stopRecordingMovie() {
        
        self.movieOutput.stopRecording()
        
    }
    
    //MARK: - AVCaptureFileOutputRecordingDelegate

    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("didStartRecordingTo...")
        
        startTimer()
        
        self.startClosure?()
    }
    
    private func startTimer() {
        cancelTimer()
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self , selector: #selector(timerFiredAction), userInfo: nil, repeats: true)
    }
    
    private func cancelTimer() {
        if self.timer != nil {
            self.timer?.invalidate()
            self.timer = nil
            self.duration = 0
        }
    }
    
    @objc private func timerFiredAction() {
        
        self.duration += 1
        print("recording movie duration: \(self.duration)")
        
        self.recordingClosure?(self.duration)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else {
            print("Error, recording movie: \(error as Any)")
            cancelTimer()
            return
        }
        
        // 录像结束，保存到沙盒，不需要保存到系统相册
        print("didFinishRecordingTo:\(outputFileURL)")
        
        self.finishClosure?(outputFileURL)
        
        cancelTimer()
        
    }
    
}

extension AVCaptureVideoOrientation {
    var uiDeviceOrientation: UIDeviceOrientation {
        get {
            switch self {
            case .landscapeLeft:        return .landscapeLeft
            case .landscapeRight:       return .landscapeRight
            case .portrait:             return .portrait
            case .portraitUpsideDown:   return .portraitUpsideDown
            @unknown default:
                return .portrait
            }
        }
    }
    
    // AVCaptureVideoOrientation(ui:UIDevice.current.orientation)
    init(ui:UIDeviceOrientation) {
        switch ui {
        case .landscapeRight:       self = .landscapeRight
        case .landscapeLeft:        self = .landscapeLeft
        case .portrait:             self = .portrait
        case .portraitUpsideDown:   self = .portraitUpsideDown
        default:                    self = .portrait
        }
    }
}
