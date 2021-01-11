//
//  AppDelegate.swift
//  Caption
//
//  Created by Qian on 2021/1/10.
//

import UIKit

extension AppDelegate {
    static var current: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        showRootVC()
        
        return true
    }
    
    func showRootVC() {
        
        let vc = CaptureViewController()
        let nav = UINavigationController(rootViewController: vc)
        
        let rootVC:UIViewController = nav
        
        window = UIWindow.init()
        window?.frame = UIScreen.main.bounds
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()
    }


}

