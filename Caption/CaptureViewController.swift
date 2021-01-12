//
//  CaptureViewController.swift
//  Caption
//
//  Created by Qian on 2021/1/11.
//

import UIKit
import MobileCoreServices
import Photos

let savePath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/saved.mp4"

class CaptureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.sourceType = .photoLibrary
        picker.videoMaximumDuration = 60
        picker.allowsEditing = true
        picker.delegate = self
        
        return picker
    }()
    
    private var mediaURL: NSURL? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .gray

        configNavi()
    }

    private func configNavi() {
        
        let selectBtn = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 40, height: 40)))
        selectBtn.setTitle("Select Video", for: .normal)
        selectBtn.setTitleColor(.black, for: .normal)
        selectBtn.addTarget(self, action: #selector(selectBtnAction), for: .touchUpInside)
        
        let leftItem = UIBarButtonItem(customView: selectBtn)
        
        navigationItem.leftBarButtonItem = leftItem
        
        let nextBtn = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 40, height: 40)))
        nextBtn.setTitle("Next", for: .normal)
        nextBtn.setTitleColor(.black, for: .normal)
        nextBtn.addTarget(self, action: #selector(nextBtnAction), for: .touchUpInside)
        
        let rightItem = UIBarButtonItem(customView: nextBtn)
        
        navigationItem.rightBarButtonItem = rightItem
        
    }
    
    @objc private func selectBtnAction() {
        
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    
    @objc private func nextBtnAction() {
        
        guard let urlString = mediaURL?.absoluteString else {
            Toast.showTips("Please select video first")
            return
        }
        
        let videoPlayerVC = VideoPlayerViewController(videoURL: URL(fileURLWithPath: urlString))
        
        self.navigationController?.pushViewController(videoPlayerVC, animated: true)
    }
    
    // MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let mediaURL = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL else {
            return
        }
        
        print(mediaURL)
        self.mediaURL = mediaURL
        
        guard let videoURL = URL(string: mediaURL.absoluteString!) else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        
        saveVideoToSandbox(url: videoURL)
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func saveVideoToSandbox(url videoURL: URL) {
        
        do {
            try FileManager.default.removeItem(atPath: savePath)
        } catch {
            print("cannot remove exist video file")
        }
        
        let asset = AVAsset(url: videoURL)
        guard asset.isExportable else {
            print("cannot export")
            return
        }
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            print("export session error")
            return
        }
        exportSession.outputURL = URL(fileURLWithPath: savePath)
        exportSession.outputFileType = .mp4
        exportSession.exportAsynchronously {
            print("export video...")
            let status = exportSession.status
            
            switch status {
            
            case .unknown:
                break
            case .waiting:
                break
            case .exporting:
                break
            case .completed:
                print("export video completed")
            case .failed:
                print(exportSession.error as Any)
                Toast.showTips(exportSession.error!.localizedDescription)
                print("export video failed")
            case .cancelled:
                break
            @unknown default:
                break
            }
        }
    }
    
}
