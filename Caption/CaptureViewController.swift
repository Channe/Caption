//
//  CaptureViewController.swift
//  Caption
//
//  Created by Qian on 2021/1/11.
//

import UIKit
import MobileCoreServices
import Photos

let savePath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/saved.mp4"

class CaptureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.sourceType = .photoLibrary
        picker.videoMaximumDuration = 60
        picker.allowsEditing = true
        picker.delegate = self
        
        return picker
    }()
    
//    private var mediaURL: NSURL? = nil
    
    private var captureController: CaptureController? = nil
    
    private lazy var flashBtn: UIButton = {
        let btn = TTButton(title: "Flash", target: self , action: #selector(flashBtnAction))
        
        return btn
    }()
    
    private lazy var switchCameraBtn: UIButton = {
        let btn = TTButton(title: "Switch", target: self , action: #selector(switchCameraBtnAction))
        
        return btn
    }()
    
    private lazy var startCaptureView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .groupTableViewBackground
        view.isUserInteractionEnabled = true
        
        let longPress = UILongPressGestureRecognizer(target: self , action: #selector(startCaptureAction(gesture:)))
        view.addGestureRecognizer(longPress)
        
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .gray

        configViews()
        
        self.captureController = CaptureController(inView: self.view, saveToURL: URL(fileURLWithPath: savePath))
        self.captureController?.startSession()
    }
    
    private func configViews() {
        configNavi()
        
        self.view.addSubview(self.switchCameraBtn)
        self.switchCameraBtn.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().offset(-20)
            maker.width.height.equalTo(60)
            maker.centerY.equalToSuperview()
        }
        
        self.view.addSubview(self.flashBtn)
        self.flashBtn.snp.makeConstraints { (maker) in
            maker.right.equalTo(self.switchCameraBtn.snp.right)
            maker.bottom.equalTo(self.switchCameraBtn.snp.top).offset(-20)
            maker.width.height.equalTo(60)
        }
        
        self.view.addSubview(self.startCaptureView)
        self.startCaptureView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.width.height.equalTo(100)
            maker.bottom.equalToSuperview().offset(-60)
        }
    }

    private func configNavi() {
        
        let selectBtn = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 40, height: 40)))
        selectBtn.setTitle("Select Video", for: .normal)
        selectBtn.setTitleColor(.black, for: .normal)
        selectBtn.addTarget(self, action: #selector(selectBtnAction), for: .touchUpInside)
        
        let leftItem = UIBarButtonItem(customView: selectBtn)
        
        navigationItem.leftBarButtonItem = leftItem
        
        let nextBtn = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 40, height: 40)))
        nextBtn.setTitle("Next", for: .normal)
        nextBtn.setTitleColor(.black, for: .normal)
        nextBtn.addTarget(self, action: #selector(nextBtnAction), for: .touchUpInside)
        
        let rightItem = UIBarButtonItem(customView: nextBtn)
        
        navigationItem.rightBarButtonItem = rightItem
        
    }
    
    //MARK: - Actions
    
    @objc private func selectBtnAction() {
        
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    
    @objc private func flashBtnAction() {
        // 打开闪光灯
        guard let captureController = self.captureController else {
            return
        }
                
        captureController.openFlash(yesOrNo: captureController.isFlashEnable)
    }
    
    @objc private func nextBtnAction() {
        
        if FileManager.default.fileExists(atPath: savePath) == false {
            Toast.showTips("Please select or capture video first")
            return
        }
        
        let videoPlayerVC = VideoPlayerViewController(videoURL: URL(fileURLWithPath: savePath))
        
        self.navigationController?.pushViewController(videoPlayerVC, animated: true)
    }
    
    @objc private func switchCameraBtnAction() {
        
        guard let captureController = self.captureController else {
            return
        }
        
        captureController.switchCamera()
        
        if captureController.isFlashEnable {
            self.flashBtn.isHidden = false
        } else {
            self.flashBtn.isHidden = true
        }
        
    }
    
    @objc private func startCaptureAction(gesture: UILongPressGestureRecognizer) {
        
        if gesture.state == .began {
            // 长按开始
            self.captureController?.startReordingMovie()
        } else if gesture.state == .ended {
            // 长按结束
            self.captureController?.stopRecordingMovie()
        }
        
    }
    
    // MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let mediaURL = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL else {
            return
        }

        print(mediaURL)
//        self.mediaURL = mediaURL

        guard let videoURL = URL(string: mediaURL.absoluteString!) else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        
        saveVideoToSandbox(url: videoURL)
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func saveVideoToSandbox(url videoURL: URL) {
        
        do {
            try FileManager.default.removeItem(atPath: savePath)
        } catch {
            print("cannot remove exist video file")
        }
        
        let asset = AVAsset(url: videoURL)
        guard asset.isExportable else {
            print("cannot export")
            return
        }
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            print("export session error")
            return
        }
        exportSession.outputURL = URL(fileURLWithPath: savePath)
        exportSession.outputFileType = .mp4
        exportSession.exportAsynchronously {
            
            DispatchQueue.main.async {
                print("export video...")
                let status = exportSession.status
                
                switch status {
                
                case .unknown:
                    break
                case .waiting:
                    break
                case .exporting:
                    break
                case .completed:
                    print("export video completed")
                case .failed:
                    print(exportSession.error as Any)
                    Toast.showTips(exportSession.error!.localizedDescription)
                    print("export video failed")
                case .cancelled:
                    break
                @unknown default:
                    break
                }
            }
            
        }
    }
    
}
