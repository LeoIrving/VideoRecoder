//
//  ViewController.swift
//  VideoRecoder
//
//  Created by JIANGJIE BIAN on 6/10/22.
//

import MobileCoreServices
import UIKit
import AVKit
import ARKit
import SceneKit
import UniformTypeIdentifiers

var is_start = false
let filename = "position.txt"
let filename2 = "rotation.txt"
// Cannot output the data to desktop because no Permission
let dirURL = try! FileManager.default.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
let fileURL = dirURL.appendingPathComponent(filename)
let dirURL2 = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
let fileURL2 = dirURL2.appendingPathComponent(filename2)

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var videoAndImageReview = UIImagePickerController()
    var videoURL : URL?
    
    private var capture: ARCapture?
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        capture = ARCapture(view: sceneView!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.delegate  = self
        let config  = ARWorldTrackingConfiguration()
        sceneView.session.run(config)
    }
    
    //recording AR
    @IBAction func ARrecord(_ sender: UIButton){
        is_start = true
        
        if (FileManager.default.fileExists(atPath: fileURL.path)) {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("cannot remove previous file")
            }
        }
        if (FileManager.default.fileExists(atPath: fileURL2.path)) {
            do {
                try FileManager.default.removeItem(at: fileURL2)
            } catch {
                print("cannot remove previous file")
            }
        }
        
        capture?.start()
    }
    
    @IBAction func ARstop(_ sender: UIButton){
        is_start = false
        capture?.stop({(status) in print("Video exported: \(status)")})
    }
    
    //recording video
    @IBAction func record(_ sender: UIButton){
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera){
            print ("Camera Available")
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.videoQuality = .typeHigh
            imagePicker.sourceType = .camera
            imagePicker.mediaTypes = [UTType.movie.identifier]
            imagePicker.allowsEditing = false
            imagePicker.videoExportPreset = AVAssetExportPresetHEVCHighestQuality
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            print("Camera Unavailable")
        }
    }
    
    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      dismiss(animated: true, completion: nil)
      guard
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
        mediaType == (UTType.movie.identifier),
        let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL,
        UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path)
        else { return }

      // Handle a movie capture
      UISaveVideoAtPathToSavedPhotosAlbum(
        url.path,
        self,
        #selector(video(_:didFinishSavingWithError:contextInfo:)),
        nil)
    }
    
    @objc func video(
      _ videoPath: String,
      didFinishSavingWithError error: Error?,
      contextInfo info: AnyObject
    ) {
      let title = (error == nil) ? "Success" : "Error"
      let message = (error == nil) ? "Video was saved" : "Video failed to save"

      let alert = UIAlertController(
        title: title,
        message: message,
        preferredStyle: .alert)
      alert.addAction(UIAlertAction(
        title: "OK",
        style: UIAlertAction.Style.cancel,
        handler: nil))
      present(alert, animated: true, completion: nil)
    }
    
    //show library
    @IBAction func library(_ sender: UIButton) {
        videoAndImageReview.sourceType = .savedPhotosAlbum
        videoAndImageReview.delegate = self
        videoAndImageReview.mediaTypes = ["public.movie"]
        present(videoAndImageReview, animated: true, completion: nil)
    }
    
    func videoAndImageReview(_ picker:UIImagePickerController, didFinishPickingMediaWithInfo info:[String: Any]){
        videoURL = info[UIImagePickerController.InfoKey.mediaURL.rawValue] as? URL
        print("\(String(describing: videoURL))")
        self.dismiss(animated: true, completion: nil)
    }
}

extension ViewController: ARSessionDelegate{
    
    func getDocumentDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame){
        let transform = frame.camera.transform
        let angle = frame.camera.eulerAngles
        let position = transform.columns.3
        let str1 = position.description
        let str2 = angle.description
        
        if is_start == true{
            print("POSE - X:\(position.x) Y:\(position.y) Z:\(position.z)")
            print("ROTAT - X:\(angle.x) Y:\(angle.y) Z:\(angle.z)")
            
            
            guard let data1 = str1.data(using: .utf8) else{
                return
            }
            
            if let fileHandle = FileHandle(forWritingAtPath: fileURL.path){
                fileHandle.seekToEndOfFile()
                fileHandle.write(data1)
            }else{
                do{try str1.write(to:fileURL, atomically: false,  encoding: String.Encoding.utf8)}catch{ print ("Write Failure")}
            }
            
            guard let data2 = str2.data(using: .utf8) else{
                return
            }
            
            if let fileHandle = FileHandle(forWritingAtPath: fileURL2.path){
                fileHandle.seekToEndOfFile()
                fileHandle.write(data2)
            }else{
                do{try str2.write(to:fileURL2, atomically: false,  encoding: String.Encoding.utf8)}catch{ print ("Write Failure")}
            }
            
            var readString = ""
            do{
                readString = try String(contentsOf: fileURL)
            }catch {
                print("Read Failure")
            }
            
            print("Contents of the file: \(readString.lengthOfBytes(using: .utf8))")
        }
    }

}

