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
            maker.edges.equalToSuperview()
        }
        
    }
    
}
