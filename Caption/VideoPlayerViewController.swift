//
//  VideoPlayerViewController.swift
//  Caption
//
//  Created by Qian on 2021/1/11.
//

import UIKit
import AVFoundation

class VideoPlayerViewController: UIViewController {
    
    private var playerController: PlayerController
    private var captionGenerator: AudioCaptionGenerator
    
    private lazy var saveBtn: UIButton = {
        let btn = TTButton(title: "Save", target: self , action: #selector(saveBtnAction))
        return btn
    }()
    
    // 正在进行
    private lazy var captioningView: UIStackView = {
        let label = TTLabel(font: TTFontB(28), color: .white, alignment: .right)
        label.text = "Generating Captions"
        
        let activity = UIActivityIndicatorView(frame: .zero)
        activity.hidesWhenStopped = false
        activity.style = .large
        activity.color = .white
        activity.startAnimating()
        
        let stack = UIStackView(arrangedSubviews: [label, activity])
        stack.alignment = .center
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.isHidden = false
        
        stack.addBackground(color: TTBlackColor(0.35))
        return stack
    }()
    
    // 失败、点击重试
    private lazy var failedRetryBtn: UIButton = {
        let btn = TTButton(title: "Failed", target: self , action: #selector(failedRetryBtnAction))
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .red
        btn.titleLabel?.font = TTFontB(28)
        btn.titleLabel?.textAlignment = .right
        btn.isHidden = true
        
        return btn
    }()
    
    private lazy var progressView: LineProgressView = {
        let view = LineProgressView()
        view.bgColor = UIColor.blue
        view.progressColor = UIColor.black
        view.isHidden = true
        return view
    }()

    init(videoURL: URL, isVideoMirrored: Bool = false) {
        self.playerController = PlayerController(URL: videoURL, isVideoMirrored:isVideoMirrored)
        
        // 语音转文字
        self.captionGenerator = AudioCaptionGenerator(URL: URL(fileURLWithPath: savePath))
        
        super.init(nibName: nil, bundle: nil)
        
        self.playerController.progressClosure = { [weak self](result) in
            guard let self = self else { return }
            switch result {
            
            case .finish:
                self.saveBtn.isEnabled = true
                self.progressView.isHidden = true
                self.progressView.progress = 0
            case .progress(let progress):
                self.saveBtn.isEnabled = false
                self.progressView.isHidden = false
                self.progressView.progress = CGFloat(progress)
            }
        }
        
        self.captionGenerator.startClosure = { [weak self] in
            guard let self = self else { return }
            
            self.captioningView.isHidden = false
            self.failedRetryBtn.isHidden = true
        }
        
        self.captionGenerator.finishClosure = { [weak self] segmentsArray in
            guard let self = self else { return }
                        
            self.captioningView.isHidden = true
            self.failedRetryBtn.isHidden = segmentsArray != nil
            
            // 显示字幕
            let naturalTimeScale = self.playerController.naturalTimeScale
            if let segmentsArray = segmentsArray,
               let items = SubtitleService.subtitles(segmentsArray: segmentsArray, naturalTimeScale: naturalTimeScale) {
                
                var style = SubtitleStyle()
                style.font = TTFontB(20)
                style.textColor = .white
//                style.backgroundColor = TTWhiteColor(0.35)
                style.alignment = .center
                style.leftMargin = 26
                style.bottomMargin = 88
                
                let array = items.map { $0.config(style: style) }
                
                self.playerController.displaySubtitles(array)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("VideoPlayerViewController" + #function)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        configViews()
        
//        self.captionGenerator.start()
        self.captionGenerator.startFromFile()
    }
    
    private func configViews() {
        
        let playerView = self.playerController.playerView
        self.view.addSubview(playerView)
        playerView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 0, bottom: 64, right: 0))
        }
        
        self.view.addSubview(self.saveBtn)
        self.saveBtn.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().offset(-20)
            maker.bottom.equalToSuperview().offset(-20)
            maker.width.height.equalTo(60)
        }
        
        self.view.addSubview(self.captioningView)
        self.captioningView.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().offset(-20)
            maker.top.equalToSuperview().offset(100)
            maker.height.equalTo(40)
        }
        
        self.view.addSubview(self.failedRetryBtn)
        self.failedRetryBtn.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().offset(-20)
            maker.top.equalToSuperview().offset(100)
            maker.height.equalTo(40)
        }
        
        self.view.addSubview(self.progressView)
        self.progressView.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.saveBtn)
            make.left.equalTo(20)
            make.right.equalTo(self.saveBtn.snp.left).offset(-20)
            make.height.equalTo(6)
        }
        
    }
    
    @objc private func failedRetryBtnAction() {
        // 点击重试
        self.captionGenerator.startFromFile()
    }
    
    @objc private func saveBtnAction() {
        //TODO: Qianlei 合成带字幕的新视频
        
        let outputPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/export.mp4"
        let outputURL = URL(fileURLWithPath: outputPath)
        
        if FileManager.default.fileExists(atPath: outputPath) {
            do {
                try FileManager.default.removeItem(atPath: outputPath)
            } catch {
                print("cannot remove exist video file")
            }
        }
        
        self.playerController.exportVideo(URL: outputURL) { (result) in
            switch result {
            case .success(_):
                // 沙盒文件保存到系统相册
                PhotosTools.saveVideoToAlbum(fromURL: outputURL) { success in
                    Toast.showTips("Save to album \(success ? "sucess" : "failed")")
                }
                break
            case .failure(_):
                Toast.showTips("Save failure.")
                break
            }
        }

    }
    
}
