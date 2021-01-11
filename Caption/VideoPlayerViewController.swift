//
//  VideoPlayerViewController.swift
//  Caption
//
//  Created by Qian on 2021/1/11.
//

import UIKit
import MobileCoreServices

class VideoPlayerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.sourceType = .photoLibrary
        picker.delegate = self
        
        return picker
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = .blue
        
        configNavi()
    }
    
    private func configNavi() {
        
        let readBtn = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 40, height: 40)))
        readBtn.setTitle("Video", for: .normal)
        readBtn.addTarget(self, action: #selector(readVideoBtnAction), for: .touchUpInside)
        
        let item = UIBarButtonItem(customView: readBtn)
        
        navigationItem.rightBarButtonItem = item
        
    }
    
    @objc private func readVideoBtnAction() {
        
        self.present(imagePicker, animated: true, completion: nil)
        
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
        
        picker.dismiss(animated: true, completion: nil)
    }

}
