//
//  PhotosTools.swift
//  Caption
//
//  Created by Qian on 2021/1/15.
//

import UIKit
import Photos

class PhotosTools {
    
    static func readVideoFromAlbum(fromURL: URL, toURL: URL) {
        //TODO: Qianlei 从相册读取视频到沙盒
        
    }

    static func saveVideoToAlbum(fromURL: URL, completion: ((Bool) -> Void)? = nil) {
        
        PHPhotoLibrary.requestAuthorization { (auth) in
            
            DispatchQueue.main.async {
                switch auth {
                case .notDetermined:
                    break
                case .restricted:
                    completion?(false)
                    SysFunc.openAppSettings()
                case .denied:
                    completion?(false)
                    SysFunc.openAppSettings()
                case .authorized:
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fromURL)
                    } completionHandler: { (success, error) in
                        if error != nil {
                            print("saveVideoToAlbum error:\(error!)")
                        }
                        completion?(success)
                    }
                case .limited:
                    completion?(false)
                    SysFunc.openAppSettings()
                @unknown default:
                    break
                }
            }
        }
    }
    
}
