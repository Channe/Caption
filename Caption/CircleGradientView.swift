//
//  CircleGradientView.swift
//  Caption
//
//  Created by Qian on 2021/1/13.
//

import UIKit

class CircleGradientView: UIView {

    // 环形进度
    public var progess:CGFloat = 0 {
        didSet {
            self.maskLayer.strokeEnd = progess
        }
    }
    
    // 环形的宽
    private var lineWidth:CGFloat = 4
    
    private let strokeColor = TTWhiteColor().cgColor
    
    private var didLoad:Bool = false
    
    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [self.startColor.cgColor,self.endColor.cgColor]
        layer.startPoint = .zero
        layer.endPoint = CGPoint(x: 0, y: 1)
        return layer
    }()
    
    // 进度条的layer层
    private lazy var maskLayer:CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = strokeColor
        layer.strokeEnd = 0
        layer.lineCap = .round
        return layer
    }()
    
    private var startColor:UIColor = .white
    private var endColor: UIColor = .white
    
    convenience init(lineWidth:CGFloat = 4, startColor:UIColor, endColor:UIColor) {
        self.init()
        
        self.lineWidth = lineWidth
        self.startColor = startColor
        self.endColor = endColor
        
        self.layer.addSublayer(gradientLayer)

        gradientLayer.mask = self.maskLayer
    }
    
    override func draw(_ rect: CGRect) {
        
        guard didLoad == false else {
            return
        }
        
        let width = rect.size.width
        let height = rect.size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        
        let center = CGPoint(x: width/2, y: height/2)
        let bezierPath = UIBezierPath(arcCenter: center, radius: (width-self.lineWidth)/2, startAngle: CGFloat(-0.5*Double.pi), endAngle: CGFloat(1.5*Double.pi), clockwise: true)
        
        gradientLayer.frame = bounds
        
        maskLayer.frame = bounds
        maskLayer.lineWidth = self.lineWidth
        maskLayer.path = bezierPath.cgPath
        
        didLoad = true
    }

}
