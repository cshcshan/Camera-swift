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
  
  private var imagePicker: UIImagePickerController!
  private var isCamera = false
  private var videoURL: NSURL?

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    print("Camera: \(UIImagePickerController.availableMediaTypesForSourceType(.Camera))")
    print("PhotoLibrary: \(UIImagePickerController.availableMediaTypesForSourceType(.PhotoLibrary))")
    print("SavedPhotosAlbum: \(UIImagePickerController.availableMediaTypesForSourceType(.SavedPhotosAlbum))")
    self.setupUI()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // MARK: - Setup
  private func setupUI() {
    self.imagePicker = UIImagePickerController()
    // mediaTypes 只要顯示的媒體類型，未設定則只顯示 image
    self.imagePicker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String] // from MobileCoreServices module
    self.imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String] // from MobileCoreServices module
    self.imagePicker.allowsEditing = false
    self.imagePicker.delegate = self
//    self.imagePicker.allowsEditing = true // can move and scale image
    self.image_Button.selected = true
    self.video_Button.selected = true
    let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
    gesture.numberOfTapsRequired = 1
    gesture.numberOfTouchesRequired = 1
    self.video_ImageView.userInteractionEnabled = true
    self.video_ImageView.addGestureRecognizer(gesture)
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
      if self.isCamera {
        self.saveImageToLibrary(image!)
      }
      picker.dismissViewControllerAnimated(true) {
        self.imageView.image = image
      }
    } else if mediaType == kUTTypeMovie as String {
      // UIImagePickerControllerMediaURL
      let movieUrl = info[UIImagePickerControllerMediaURL] as! NSURL
      guard let videoPath = movieUrl.path else { return }
      if self.isCamera {
        self.saveVideoToLibrary(videoPath)
      }
      picker.dismissViewControllerAnimated(true) {
        self.videoURL = movieUrl
        self.playVideoScreenShot(movieUrl)
      }
    }
  }
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
    print("imagePickerController(_:didFinishPickingMediaWithInfo:editingInfo:) editingInfo: \(editingInfo)")
  
  }
  
  // MARK: - IBAction
  @IBAction func cameraButtonPressed(sender: UIButton) {
    self.presentImagePickerController(.Camera)
  }
  
  @IBAction func photoLibraryButtonPressed(sender: UIButton) {
    self.presentImagePickerController(.PhotoLibrary)
  }
  
  @IBAction func savedPhotoAlbumButtonPressed(sender: UIButton) {
    self.presentImagePickerController(.SavedPhotosAlbum)
  }
  
  @IBAction func imageButtonPressed(sender: UIButton) {
    var mediaTypes: [String] = self.imagePicker.mediaTypes
    self.image_Button.selected = !self.image_Button.selected
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
      self.video_Button.selected = true
    }
    self.imagePicker.mediaTypes = mediaTypes
  }
  
  @IBAction func videoButtonPressed(sender: UIButton) {
    var mediaTypes: [String] = self.imagePicker.mediaTypes
    self.video_Button.selected = !self.video_Button.selected
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
      self.image_Button.selected = true
    }
    self.imagePicker.mediaTypes = mediaTypes
  }
  
  @IBAction func checkAuthorizationButtonPressed(sender: UIButton) {
    self.checkAuthorize()
  }
  
  // MARK: - Utilities
  private func presentImagePickerController(sourceType: UIImagePickerControllerSourceType) {
    self.isCamera = sourceType == UIImagePickerControllerSourceType.Camera
    if UIImagePickerController.isSourceTypeAvailable(sourceType) {
      self.imagePicker.sourceType = sourceType
      self.presentViewController(self.imagePicker, animated: true) {
      }
    }
  }
  
  // 檢查相機使用權限
  private func checkAuthorize() {
    let authorizeStatuse = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
    if authorizeStatuse == AVAuthorizationStatus.Authorized {
      // 已取得使用權限
      self.showAlertAction("Check Authorize", message: "Authorized")
    } else if authorizeStatuse == AVAuthorizationStatus.Denied {
      // 拒絕提供使用權限，提示使用者到設定開啟
      self.showAlertAction("Check Authorize", message: "Denied")
    } else if authorizeStatuse == AVAuthorizationStatus.Restricted {
      // 通常不會發生
      self.showAlertAction("Check Authorize", message: "Restricted")
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
      self.showAlertAction("Check Authorize", message: "Not Determined")
    }
  }
  
  private func showAlertAction(title: String, message: String) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
    alertController.addAction(okAction)
    self.presentViewController(alertController, animated: true, completion: nil)
  }
  
  // Save to Sandbox
  private func saveImageToDocuments(image: UIImage) {
    let documentPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    let pngPath = (documentPath as NSString).stringByAppendingPathComponent("image.png")
    let jpegPath = (documentPath as NSString).stringByAppendingPathComponent("image.jpg")
    let compressionQuality: CGFloat = 0.5
    let imagePng_Data = UIImagePNGRepresentation(image)
    let imageJpeg_Data = UIImageJPEGRepresentation(image, compressionQuality)
    NSFileManager.defaultManager().createFileAtPath(pngPath, contents: imagePng_Data, attributes: nil)
    NSFileManager.defaultManager().createFileAtPath(jpegPath, contents: imageJpeg_Data, attributes: nil)
  }
  
  // Save Image to Image Library
  private func saveImageToLibrary(image: UIImage) {
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
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
    self.presentViewController(avPlayerViewController, animated: true) {
      
    }
  }
  
  private func playVideoScreenShot(videoURL: NSURL) {
    let avPlayer = AVPlayer(URL: videoURL)
    let avAsset = avPlayer.currentItem?.asset
//    let avAssetTrack = avAsset?.tracksWithMediaType(AVMediaTypeVideo).first
//    let videoSize = avAssetTrack?.naturalSize
//    let videoTransform = avAssetTrack?.preferredTransform
    let imageGenerator = AVAssetImageGenerator(asset: avAsset!)
    imageGenerator.maximumSize = self.video_ImageView.frame.size
    imageGenerator.appliesPreferredTrackTransform = true // 取得正確方向的截圖
    var actualTime: CMTime = kCMTimeZero
    do {
      let cgImageRef = try imageGenerator.copyCGImageAtTime(avPlayer.currentTime(), actualTime: &actualTime)
      self.video_ImageView.image = UIImage(CGImage: cgImageRef)
    } catch let error as NSError {
      print("playVideoScreenShot error: \(error)")
    }
  }
  
  // MARK: 
  func handleTapGesture(gesture: UIGestureRecognizer) {
    if self.videoURL != nil {
      self.playVideo(self.videoURL!)
    }
  }
}

