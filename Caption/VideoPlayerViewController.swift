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
    
    init(videoURL: URL) {
        self.playerControlloer = PlayerController(URL: videoURL)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = .white
        
        configPlayerViews()
    }
    
    private func configPlayerViews() {
        
        let playerView = self.playerControlloer.playerView
        self.view.addSubview(playerView)
        playerView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 100, left: 20, bottom: 40, right: 20))
        }
        
    }
    
}
