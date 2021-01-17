//
//  Toast.swift
//
//
//  Created by Qian on 2020/5/9.
//  Copyright © 2020 tt. All rights reserved.
//

import UIKit
import SnapKit

struct Toast {
    
    private static var maskView:UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }()
    
    private static var bgView:UIView = {
        let view = UIView(frame: .zero)
        view.alpha = 0
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        view.backgroundColor = .black
        
        return view
    }()
    
    private static var loading:UIActivityIndicatorView = {
        let ind = UIActivityIndicatorView()
        ind.style = .white
        ind.backgroundColor = .clear
        ind.hidesWhenStopped = true
        return ind
    }()
    
    private static var tipsLabel:UILabel = {
        let label = TTLabel(font: TTFontM(22), color: TTColor("#C5C5C7"), alignment: .center)
        label.numberOfLines = 10
        label.lineBreakMode = .byWordWrapping
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.backgroundColor = .black
        label.alpha = 1
        
        return label
    }()
    
    static func showTips(_ msg:String, duration:Double = 2, execute: @escaping () -> Void) {
        self.showTips(msg, duration: duration)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: execute)
    }
    
    static func showTips(_ msg:String, duration:Double = 2) {
        DispatchQueue.main.async {
            print("will showTips:\(msg)")
            guard !msg.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
            
            guard let view = AppDelegate.current.window else {
                return
            }
            
            bgView.subviews.forEach { $0.removeFromSuperview() }
            view.addSubview(bgView)
            bgView.addSubview(tipsLabel)
            bgView.backgroundColor = .black
            
            tipsLabel.text = msg
            tipsLabel.sizeToFit()
            
            tipsLabel.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.equalTo(20)
                make.bottom.greaterThanOrEqualTo(-20)
                make.left.greaterThanOrEqualTo(20)
                make.right.greaterThanOrEqualTo(-20)
                make.width.greaterThanOrEqualTo(60)
                make.height.greaterThanOrEqualTo(12)
            }
            
            bgView.snp.remakeConstraints { (make) in
                make.center.equalToSuperview()
                make.width.greaterThanOrEqualTo(144)
                make.left.lessThanOrEqualTo(50)
                make.height.greaterThanOrEqualTo(20*2+12)
                make.right.lessThanOrEqualTo(-50)
            }
            
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                bgView.alpha = 1
            }, completion: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                    bgView.alpha = 0
                }) { _ in
                    bgView.removeFromSuperview()
                }
            }
        }
    }
    
    static func showLoading(functionName: StaticString = #function, isAllShowing: Bool = false) {
        
        let view = AppDelegate.current.window!
        
        DispatchQueue.main.async {
            maskView.subviews.forEach { $0.removeFromSuperview() }
            view.addSubview(maskView)
            
            bgView.subviews.forEach { $0.removeFromSuperview() }
            maskView.addSubview(bgView)
            
            bgView.addSubview(loading)
            bgView.backgroundColor = UIColor.black.withAlphaComponent(CGFloat(0.75))
            
            maskView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
            bgView.snp.remakeConstraints { (make) in
                make.center.equalToSuperview()
                make.width.height.equalTo(64)
            }
            
            loading.snp.remakeConstraints { (make) in
                make.center.equalTo(bgView)
                make.width.height.equalTo(20)
            }
            
            loading.startAnimating()
        }
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                bgView.alpha = 1
            }, completion: nil)
        }
        if !isAllShowing { // 不需要一直显示
            DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
                self.hideLoading()
            }
        }
        
        
    }
    
    
    
    static func hideLoading(functionName: StaticString = #function) {
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                bgView.alpha = 0
            }) { _ in
                maskView.removeFromSuperview()
            }
        }
    }
    
}
