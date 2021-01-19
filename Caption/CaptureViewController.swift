//
//  CaptureViewController.swift
//  Caption
//
//  Created by Qian on 2021/1/11.
//

import UIKit
import MobileCoreServices
import Photos

let savePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/saved.mp4"

class CaptureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private let videoMaxDuration: TimeInterval  = 60.0
    
    private lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.sourceType = .photoLibrary
        picker.videoMaximumDuration = videoMaxDuration
        picker.videoQuality = .typeHigh
        picker.videoExportPreset = AVAssetExportPresetHighestQuality
        picker.allowsEditing = true
        picker.delegate = self
        
        return picker
    }()
        
    private var captureController: CaptureController? = nil
    
    //TODO: qianlei 改用 UIStackView: Flash/Switch/Select Btns
    private lazy var flashBtn: UIButton = {
        let btn = TTButton(title: "Flash", target: self , action: #selector(flashBtnAction))
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 60/2
        btn.isHidden = true
        return btn
    }()
    
    private lazy var switchCameraBtn: UIButton = {
        let btn = TTButton(title: "Switch", target: self , action: #selector(switchCameraBtnAction))
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 60/2
        return btn
    }()
    
    private lazy var selectBtn: UIButton = {
        let btn = TTButton(title: "Select", target: self , action: #selector(selectBtnAction))
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 60/2
        return btn
    }()
    
    private lazy var cancelBtn: UIButton = {
        let btn = TTButton(title: "NO", target: self , action: #selector(cancelCaptureAction))
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 50/2
        btn.isHidden = true
        return btn
    }()
    
    private lazy var nextBtn: UIButton = {
        let btn = TTButton(title: "OK", target: self , action: #selector(nextBtnAction))
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 50/2
        btn.isHidden = true
        return btn
    }()
    
    private lazy var durationLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.font = TTFontB(24)
        label.adjustsFontSizeToFitWidth = true
        label.textColor = .white
        label.text = ""
        label.backgroundColor = .white
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 36/2
        
        return label
    }()
    
    private lazy var circelGradientView: CircleGradientView = {
        let view = CircleGradientView(lineWidth: 8, startColor: .white, endColor: .white)
        view.isHidden = true
        return view
    }()
    
    private lazy var startCaptureView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = TTBlackColor(0.3)
        view.isUserInteractionEnabled = true
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 90/2
        
        let longPress = UILongPressGestureRecognizer(target: self , action: #selector(startCaptureAction(gesture:)))
        view.addGestureRecognizer(longPress)
        
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .gray

        configViews()
        
        self.captureController = CaptureController(inView: self.view, saveToURL: URL(fileURLWithPath: savePath))
        self.captureController?.startClosure = { [weak self] in
            guard let self = self else { return }
            self.showProgress(duration: 0)
        }
        
        self.captureController?.recordingClosure = { [weak self] duration in
            guard let self = self else { return }
            self.showProgress(duration: duration)
        }
        
        self.captureController?.finishClosure = { [weak self] outputURL, duration in
            guard let self = self else { return }
            print("finishClosure:\(outputURL)")
            self.showCancelBtn(true)
            self.showProgress(duration: duration)
        }
        
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
        
        self.view.addSubview(self.selectBtn)
        self.selectBtn.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().offset(-20)
            maker.width.height.equalTo(60)
            maker.top.equalTo(self.switchCameraBtn.snp.bottom).offset(20)
        }
        
        self.view.addSubview(self.flashBtn)
        self.flashBtn.snp.makeConstraints { (maker) in
            maker.right.equalTo(self.switchCameraBtn.snp.right)
            maker.bottom.equalTo(self.switchCameraBtn.snp.top).offset(-20)
            maker.width.height.equalTo(60)
        }
        
        self.view.addSubview(self.circelGradientView)
        self.circelGradientView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.width.height.equalTo(116)
            maker.bottom.equalToSuperview().offset(-60)
        }
        
        self.view.addSubview(self.startCaptureView)
        self.startCaptureView.snp.makeConstraints { (maker) in
            maker.center.equalTo(self.circelGradientView)
            maker.width.height.equalTo(90)
        }
        
        self.startCaptureView.addSubview(self.durationLabel)
        self.durationLabel.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(36)
            maker.center.equalToSuperview()
        }
        
        self.view.addSubview(self.cancelBtn)
        self.cancelBtn.snp.makeConstraints { (maker) in
            maker.right.equalTo(self.startCaptureView.snp.left).offset(-40)
            maker.width.height.equalTo(50)
            maker.centerY.equalTo(self.startCaptureView)
        }
        
        self.view.addSubview(self.nextBtn)
        self.nextBtn.snp.makeConstraints { (maker) in
            maker.left.equalTo(self.startCaptureView.snp.right).offset(40)
            maker.width.height.equalTo(50)
            maker.centerY.equalTo(self.startCaptureView)
        }
    }

    private func configNavi() {
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
//        let selectBtn = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 40, height: 40)))
//        selectBtn.setTitle("Select Video", for: .normal)
//        selectBtn.setTitleColor(.black, for: .normal)
//        selectBtn.addTarget(self, action: #selector(selectBtnAction), for: .touchUpInside)
//
//        let leftItem = UIBarButtonItem(customView: selectBtn)
//
//        navigationItem.leftBarButtonItem = leftItem
        
    }
    
    private func showCancelBtn(_ yesOrNo: Bool) {
        self.cancelBtn.isHidden = !yesOrNo
        self.nextBtn.isHidden = !yesOrNo
    }
    
    private func showProgress(duration: TimeInterval?) {
        
        guard let duration = duration else {
            self.durationLabel.text = ""
            self.durationLabel.backgroundColor = .white
            
            self.circelGradientView.isHidden = true
            self.circelGradientView.progess = 0.0
            return
        }
        
        let roundDuration = round(duration)
//        let ceilDuration = ceil(duration)
        let displayDuration = roundDuration
        self.durationLabel.text = "\(String(format: "%.0f", displayDuration))s"

        self.durationLabel.backgroundColor = .clear
        
        self.circelGradientView.isHidden = false
        self.circelGradientView.progess = CGFloat(displayDuration / videoMaxDuration)
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
    
    @objc private func cancelCaptureAction() {
        print(#function)
        
        showCancelBtn(false)
        showProgress(duration: nil)
        
        do {
            try FileManager.default.removeItem(atPath: savePath)
        } catch {
            print("remove file error:\(error)")
        }
    }
    
    @objc private func nextBtnAction() {
        
        if FileManager.default.fileExists(atPath: savePath) == false {
            Toast.showTips("Please select or capture video first")
            return
        }
        
        let isVideoMirrored = self.captureController?.isVideoMirrored ?? false
        let videoPlayerVC = VideoPlayerViewController(videoURL: URL(fileURLWithPath: savePath), isVideoMirrored: isVideoMirrored)
        
        self.navigationController?.pushViewController(videoPlayerVC, animated: true)
    }
    
    @objc private func switchCameraBtnAction() {
        
        guard let captureController = self.captureController else {
            return
        }
        
        captureController.switchCamera()
        
//        if captureController.isFlashEnable {
//            self.flashBtn.isHidden = false
//        } else {
//            self.flashBtn.isHidden = true
//        }
        
    }
    
    @objc private func startCaptureAction(gesture: UILongPressGestureRecognizer) {
        
        if gesture.state == .began {
            // 长按开始
//            SysFunc.feedbackGenerator()
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
        
        // 获取编辑后的视频 URL
        guard let mediaURL = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL,
              let videoURL = URL(string: mediaURL.absoluteString!) else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        
        saveVideoToSandbox(url: videoURL)
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func saveVideoToSandbox(url videoURL: URL) {
        
        Toast.showLoading()
        
        if FileManager.default.fileExists(atPath: savePath) {
            do {
                try FileManager.default.removeItem(atPath: savePath)
            } catch {
                print("cannot remove exist video file")
            }
        }
        
        let asset = AVAsset(url: videoURL)
        guard asset.isExportable else {
            print("cannot export,asset")
            Toast.hideLoading()
            return
        }

        guard let composition = VideoTools.buildComposition(asset: asset) else {
            print("cannot export,composition")
            Toast.hideLoading()
            return
        }

        guard let session = VideoTools.buildExportSession(outputURL: URL(fileURLWithPath: savePath), composition: composition, asset: asset) else {
            print("AVAssetExportSession error")
            return
        }

        session.exportAsynchronously {
            Toast.hideLoading()
            
            DispatchQueue.main.async {
                print("export video...: \(savePath)")
                let status = session.status
                switch status {
                case .unknown:
                    break
                case .waiting:
                    break
                case .exporting:
                    break
                case .completed:
                    print("export video completed")
                    self.showCancelBtn(true)
                    let asset = AVAsset(url: URL(fileURLWithPath: savePath))
                    self.showProgress(duration: asset.duration.seconds)
                case .failed:
                    print(session.error as Any)
                    Toast.showTips(session.error!.localizedDescription)
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
