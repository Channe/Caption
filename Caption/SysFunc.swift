//
//  SysFunc.swift
//  Caption
//
//  Created by Qian on 2021/1/13.
//

import UIKit
import AudioToolbox

class SysFunc {
    
    //TODO: qianlei 没有震动效果
    public static func feedbackGenerator() {
//        let gen = UIImpactFeedbackGenerator(style: .heavy)
        let gen = UISelectionFeedbackGenerator()
        gen.prepare()
//        gen.impactOccurred()
        gen.selectionChanged()
        
//        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
//        AudioServicesPlaySystemSound(1519)
    }
    
    public static func openAppSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, completionHandler: nil)
    }
    
}
