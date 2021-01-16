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

    init(videoURL: URL, isVideoMirrored: Bool = false) {
        self.playerController = PlayerController(URL: videoURL, isVideoMirrored:isVideoMirrored)
        
        // 语音转文字
        self.captionGenerator = AudioCaptionGenerator(URL: URL(fileURLWithPath: savePath))
        
        super.init(nibName: nil, bundle: nil)
        
        self.captionGenerator.startClosure = { [weak self] in
            guard let self = self else { return }
            
            self.captioningView.isHidden = false
            self.failedRetryBtn.isHidden = true
        }
        
        self.captionGenerator.finishClosure = { [weak self] success in
            guard let self = self else { return }
            
            self.captioningView.isHidden = true
            self.failedRetryBtn.isHidden = success
            
            if success {
                let text = self.captionGenerator.finalText
                // 显示字幕
                print("finalText:\(text)")
                
                //TODO: qianlei 字幕时间
                let font = TTFontB(26)
                let subtitleItem1 = SubtitleItem(text: text, timestamp: 1, duration: 5, font: font)
                let subtitleItem2 = SubtitleItem(text: "第二段字幕 test", timestamp: 6, duration: 5, font: font)

                self.playerController.displaySubtitles([subtitleItem1, subtitleItem2])
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
        
        configPlayerViews()
        
//        self.captionGenerator.start()
        self.captionGenerator.startFromFile()
    }
    
    private func configPlayerViews() {
        
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

        Toast.showTips("exporting...")
        
        self.playerController.exportVideo(URL: outputURL) { (result) in

            switch result {
            
            case .success(_):
                // 沙盒文件保存到系统相册
                Toast.showTips("export success.")
                PhotosTools.saveVideoToAlbum(fromURL: outputURL)
                break
            case .failure(_):
                Toast.showTips("export failure.")

                break
            }
        }

    }
    
}
