//
//  VideoPlayerViewController.swift
//  Caption
//
//  Created by Qian on 2021/1/11.
//

import UIKit

class VideoPlayerViewController: UIViewController {
    
    var videoURL: NSURL
    
    init(videoURL: NSURL) {
        self.videoURL = videoURL
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = .blue
        
    }
    
    

}
