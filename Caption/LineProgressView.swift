//
//  LineProgressView.swift
//  Caption
//
//  Created by Qian on 2021/1/20.
//

import UIKit

class LineProgressView: UIView {

    // 进度
    public var progress:CGFloat = 0 {
        didSet {
            var frame = processLayer.frame
            frame.size.width = self.bounds.width * progress
            processLayer.frame = frame
        }
    }
    
    var progressColor = TTWhiteColor(){
        didSet {
            self.processLayer.backgroundColor = progressColor.cgColor
        }
    }
    var bgColor: UIColor = TTBlackColor(0.75) {
        didSet {
            self.backgroundColor = bgColor
        }
    }

    private var didLoad:Bool = false
    
    private lazy var processLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = progressColor.cgColor
        return layer
    }()
    
    convenience init() {
        self.init(frame:.zero)
        
        self.backgroundColor = bgColor
        self.layer.addSublayer(processLayer)
    }
    
    override func draw(_ rect: CGRect) {
        
        guard didLoad == false else {
            return
        }
        didLoad = true
        
        let width = rect.size.width
        let height = rect.size.height
        let maskWidth:CGFloat = width * progress
        
        self.layer.cornerRadius = height / 2.0
        self.layer.masksToBounds = true
        processLayer.frame = CGRect(x: 0, y: 0, width: maskWidth, height: height)
        processLayer.cornerRadius = height / 2.0
        processLayer.masksToBounds = true
    }

}
