//
//  PhotosTools.swift
//  Caption
//
//  Created by Qian on 2021/1/15.
//

import UIKit
import Photos

class PhotosTools {

    static func saveToAlbum(fromURL: URL) {
        
        PHPhotoLibrary.requestAuthorization { (auth) in
            
            DispatchQueue.main.async {
                switch auth {
                
                case .notDetermined:
                    break
                case .restricted:
                    SysFunc.openAppSettings()
                case .denied:
                    SysFunc.openAppSettings()
                case .authorized:
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fromURL)
                    } completionHandler: { (success, error) in
                        if error != nil {
                            print("saveToAlbum error:\(error!)")
                        }
                        Toast.showTips("Save to album \(success ? "sucess" : "failed")")
                    }
                case .limited:
                    SysFunc.openAppSettings()
                @unknown default:
                    break
                }
            }
        }
    }
    
}
