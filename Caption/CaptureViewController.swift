//
//  CaptureViewController.swift
//  Caption
//
//  Created by Qian on 2021/1/11.
//

import UIKit
import MobileCoreServices

class CaptureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.sourceType = .photoLibrary
        picker.delegate = self
        
        return picker
    }()
    
    private var mediaURL: NSURL? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
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
        
        guard let videoURL = mediaURL else {
            Toast.showTips("Please select video first")
            return
        }
        
        let videoPlayerVC = VideoPlayerViewController(videoURL: videoURL)
        
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
        // file:///Users/qian/Library/Developer/CoreSimulator/Devices/F33A8D73-40F3-48A9-A50A-14DF07F18FD4/data/Containers/Data/PluginKitPlugin/38BAA803-5033-4D97-A17A-297B58BE58D1/tmp/trim.D3E9E5B6-A78A-4C68-955B-D5E2B0A34A57.MOV
        print(mediaURL)
        self.mediaURL = mediaURL
        
        picker.dismiss(animated: true, completion: nil)
    }
    
}
