//
//  VideoPlayerViewController.swift
//  Caption
//
//  Created by Qian on 2021/1/11.
//

import UIKit
import AVFoundation

class VideoPlayerViewController: UIViewController {
    
    private var playerControlloer: PlayerController
    private var captionGenerator: AudioCaptionGenerator
    
    private lazy var saveBtn: UIButton = {
        let btn = TTButton(title: "Save", target: self , action: #selector(saveBtnAction))
        return btn
    }()
    
    init(videoURL: URL) {
        self.playerControlloer = PlayerController(URL: videoURL)
        //TODO: qianlei 提前进行语音转文字
        self.captionGenerator = AudioCaptionGenerator(URL: URL(fileURLWithPath: savePath))
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        configPlayerViews()
        
//        self.captionGenerator.start()
        self.captionGenerator.startFromFile()
    }
    
    private func configPlayerViews() {
        
        let playerView = self.playerControlloer.playerView
        self.view.addSubview(playerView)
        playerView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 0, bottom: 64, right: 0))
        }
        
        self.view.addSubview(self.saveBtn)
        self.saveBtn.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().offset(-20)
            maker.bottom.equalToSuperview().offset(-20)
        }
        
    }
    
    @objc private func saveBtnAction() {
        //TODO: Qianlei 合成带字幕的新视频
        //TODO: qianlei 沙盒文件保存到系统相册
        
    }
    
}
