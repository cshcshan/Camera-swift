//
//  ViewController.swift
//  camera-swift
//
//  Created by Han Chen on 2016/9/7.
//  Copyright © 2016年 Han Chen. All rights reserved.
//

import UIKit
import MobileCoreServices // for kUTTypeImage, kUTTypeMovie
import AVFoundation // for AVCaptureDevice, AVAuthorizationStatus, AVPlayer
import AVKit // for AVPlayerViewController

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  @IBOutlet weak var image_Button: UIButton!
  @IBOutlet weak var video_Button: UIButton!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var video_ImageView: UIImageView!
  @IBOutlet weak var save_SegmentedControl: UISegmentedControl!
  
  private var imagePicker: UIImagePickerController!
  private var isCamera = false
  private var videoURL: NSURL?

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    print("Camera: \(UIImagePickerController.availableMediaTypesForSourceType(.Camera)!)")
    print("PhotoLibrary: \(UIImagePickerController.availableMediaTypesForSourceType(.PhotoLibrary)!)")
    print("SavedPhotosAlbum: \(UIImagePickerController.availableMediaTypesForSourceType(.SavedPhotosAlbum)!)")
    setupUI()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // MARK: - Setup
  private func setupUI() {
    imagePicker = UIImagePickerController()
    // mediaTypes 只要顯示的媒體類型，未設定則只顯示 image
    imagePicker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String] // from MobileCoreServices module
    imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String] // from MobileCoreServices module
    imagePicker.allowsEditing = false
    imagePicker.delegate = self
//    imagePicker.allowsEditing = true // can move and scale image
    image_Button.selected = true
    video_Button.selected = true
    let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
    gesture.numberOfTapsRequired = 1
    gesture.numberOfTouchesRequired = 1
    video_ImageView.userInteractionEnabled = true
    video_ImageView.addGestureRecognizer(gesture)
  }
  
  // MARK: - UIImagePickerControllerDelegate
  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    print("imagePickerControllerDidCancel(_:)")
    picker.dismissViewControllerAnimated(true) {
    }
  }
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    print("imagePickerController(_:didFinishPickingMediaWithInfo:) info: \(info)")
    let mediaType = info[UIImagePickerControllerMediaType] as! String
    if mediaType == kUTTypeImage as String {
      var image = info[UIImagePickerControllerEditedImage] as? UIImage
      if image == nil {
        image = info[UIImagePickerControllerOriginalImage] as? UIImage
      }
      guard image != nil else { return }
      if isCamera {
        switch save_SegmentedControl.selectedSegmentIndex {
        case 0:
          saveImageToLibrary(image!)
        case 1:
          saveImageToDocuments(image!)
        default: break
        }
      }
      picker.dismissViewControllerAnimated(true) {
        self.imageView.image = image
      }
    } else if mediaType == kUTTypeMovie as String {
      // UIImagePickerControllerMediaURL
      let movieUrl = info[UIImagePickerControllerMediaURL] as! NSURL
      guard let videoPath = movieUrl.path else { return }
      if isCamera {
        switch save_SegmentedControl.selectedSegmentIndex {
        case 0:
          saveVideoToLibrary(videoPath)
        case 1:
          saveVideoToDocument(videoPath)
        default: break
        }
      }
      picker.dismissViewControllerAnimated(true) {
        self.videoURL = movieUrl
        self.videoScreenShot(movieUrl)
      }
    }
  }
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
    print("imagePickerController(_:didFinishPickingMediaWithInfo:editingInfo:) editingInfo: \(editingInfo)")
  
  }
  
  // MARK: - IBAction
  @IBAction func cameraButtonPressed(sender: UIButton) {
    presentImagePickerController(.Camera)
  }
  
  @IBAction func photoLibraryButtonPressed(sender: UIButton) {
    presentImagePickerController(.PhotoLibrary)
  }
  
  @IBAction func savedPhotoAlbumButtonPressed(sender: UIButton) {
    presentImagePickerController(.SavedPhotosAlbum)
  }
  
  @IBAction func imageButtonPressed(sender: UIButton) {
    var mediaTypes: [String] = imagePicker.mediaTypes
    image_Button.selected = !image_Button.selected
    if image_Button.selected {
      if mediaTypes.contains(kUTTypeImage as String) == false {
        mediaTypes.append(kUTTypeImage as String)
      }
    } else {
      if mediaTypes.contains(kUTTypeImage as String) {
        mediaTypes.removeAtIndex(mediaTypes.indexOf(kUTTypeImage as String)!)
      }
    }
    if mediaTypes.count == 0 {
      mediaTypes.append(kUTTypeMovie as String)
      video_Button.selected = true
    }
    imagePicker.mediaTypes = mediaTypes
  }
  
  @IBAction func videoButtonPressed(sender: UIButton) {
    var mediaTypes: [String] = imagePicker.mediaTypes
    video_Button.selected = !video_Button.selected
    if video_Button.selected {
      if mediaTypes.contains(kUTTypeMovie as String) == false {
        mediaTypes.append(kUTTypeMovie as String)
      }
    } else {
      if mediaTypes.contains(kUTTypeMovie as String) {
        mediaTypes.removeAtIndex(mediaTypes.indexOf(kUTTypeMovie as String)!)
      }
    }
    if mediaTypes.count == 0 {
      mediaTypes.append(kUTTypeImage as String)
      image_Button.selected = true
    }
    imagePicker.mediaTypes = mediaTypes
  }
  
  @IBAction func checkAuthorizationButtonPressed(sender: UIButton) {
    checkAuthorize()
  }
  
  // MARK: - Utilities
  private func presentImagePickerController(sourceType: UIImagePickerControllerSourceType) {
    isCamera = sourceType == UIImagePickerControllerSourceType.Camera
    if UIImagePickerController.isSourceTypeAvailable(sourceType) {
      imagePicker.sourceType = sourceType
      presentViewController(imagePicker, animated: true) {
      }
    }
  }
  
  // 檢查相機使用權限
  private func checkAuthorize() {
    let authorizeStatuse = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
    if authorizeStatuse == AVAuthorizationStatus.Authorized {
      // 已取得使用權限
      showAlertAction("Check Authorize", message: "Authorized")
    } else if authorizeStatuse == AVAuthorizationStatus.Denied {
      // 拒絕提供使用權限，提示使用者到設定開啟
      showAlertAction("Check Authorize", message: "Denied")
    } else if authorizeStatuse == AVAuthorizationStatus.Restricted {
      // 通常不會發生
      showAlertAction("Check Authorize", message: "Restricted")
    } else if authorizeStatuse == AVAuthorizationStatus.NotDetermined {
      // 尚未詢問要求權限，因此彈跳訊息
      let mediaType = kUTTypeImage
      AVCaptureDevice.requestAccessForMediaType(mediaType as String, completionHandler: { (granted) in
        if granted {
          print("Granted access to %@", mediaType)
        } else {
          print("Not granted access to %@", mediaType)
        }
      })
      showAlertAction("Check Authorize", message: "Not Determined")
    }
  }
  
  private func showAlertAction(title: String, message: String) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
    alertController.addAction(okAction)
    presentViewController(alertController, animated: true, completion: nil)
  }
  
  // Save Image to Sandbox
  private func saveImageToDocuments(image: UIImage) {
    let documentPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    var index: Int = 0
    var pngFilePath = (documentPath as NSString).stringByAppendingPathComponent(NSString(format: "image%03d.png", index) as String)
    while NSFileManager.defaultManager().fileExistsAtPath(pngFilePath) {
      index += 1
      if index > 999 {
        index = 0
      }
      pngFilePath = (documentPath as NSString).stringByAppendingPathComponent(NSString(format: "image%03d.png", index) as String)
    }
    index = 0
    var jpgFilePath = (documentPath as NSString).stringByAppendingPathComponent(NSString(format: "image%03d.jpg", index) as String)
    while NSFileManager.defaultManager().fileExistsAtPath(jpgFilePath) {
      index += 1
      if index > 999 {
        index = 0
      }
      jpgFilePath = (documentPath as NSString).stringByAppendingPathComponent(NSString(format: "image%03d.jpg", index) as String)
    }
    let compressionQuality: CGFloat = 0.5
    let imagePng_Data = UIImagePNGRepresentation(image)
    let imageJpeg_Data = UIImageJPEGRepresentation(image, compressionQuality)
    NSFileManager.defaultManager().createFileAtPath(pngFilePath, contents: imagePng_Data, attributes: nil) // png 存檔方向會有問題
    NSFileManager.defaultManager().createFileAtPath(jpgFilePath, contents: imageJpeg_Data, attributes: nil)
  }
  
  // Save Image to Image Library
  private func saveImageToLibrary(image: UIImage) {
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
  }
  
  // Save Video to Sandbox
  private func saveVideoToDocument(videoPath: String) {
    let video_Data = NSData(contentsOfFile: videoPath)
    let documentPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    let pathExtension = (videoPath as NSString).pathExtension
    var index: Int = 0
    var videoFilePath = (documentPath as NSString).stringByAppendingPathComponent(NSString(format: "video%03d.%@", index, pathExtension) as String)
    while NSFileManager.defaultManager().fileExistsAtPath(videoFilePath) {
      index += 1
      if index > 999 {
        index = 0
      }
      videoFilePath = (documentPath as NSString).stringByAppendingPathComponent(NSString(format: "video%03d.%@", index, pathExtension) as String)
    }
    NSFileManager.defaultManager().createFileAtPath(videoFilePath, contents: video_Data, attributes: nil)
  }
  
  // Save Video to Image Library
  private func saveVideoToLibrary(videoPath: String) {
    if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath) {
      UISaveVideoAtPathToSavedPhotosAlbum(videoPath, nil, nil, nil)
    }
  }
  
  // Play Video
  private func playVideo(videoURL: NSURL) {
    let avPlayer = AVPlayer(URL: videoURL)
    let avPlayerViewController = AVPlayerViewController()
    avPlayerViewController.player = avPlayer
    presentViewController(avPlayerViewController, animated: true) {
      
    }
  }
  
  private func videoScreenShot(videoURL: NSURL) {
    let avPlayer = AVPlayer(URL: videoURL)
    let avAsset = avPlayer.currentItem?.asset
//    let avAssetTrack = avAsset?.tracksWithMediaType(AVMediaTypeVideo).first
//    let videoSize = avAssetTrack?.naturalSize
//    let videoTransform = avAssetTrack?.preferredTransform
    let imageGenerator = AVAssetImageGenerator(asset: avAsset!)
    imageGenerator.maximumSize = video_ImageView.frame.size
    imageGenerator.appliesPreferredTrackTransform = true // 取得正確方向的截圖
    var actualTime: CMTime = kCMTimeZero
    do {
      let cgImageRef = try imageGenerator.copyCGImageAtTime(avPlayer.currentTime(), actualTime: &actualTime)
      video_ImageView.image = UIImage(CGImage: cgImageRef)
    } catch let error as NSError {
      print("playVideoScreenShot error: \(error)")
    }
  }
  
  // MARK: 
  func handleTapGesture(gesture: UIGestureRecognizer) {
    if videoURL != nil {
      playVideo(videoURL!)
    }
  }
}

