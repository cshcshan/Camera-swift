//
//  SandBoxFilesViewController.swift
//  camera-swift
//
//  Created by Han Chen on 2016/9/8.
//  Copyright © 2016年 Han Chen. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation

class SandBoxFilesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var collectionView: UICollectionView!
  
  private var file_Array: [NSURL] = []
  private var image_Array: [UIImage] = []
  
  override func viewDidLoad() {
    loadImagesAndVideos()
    setupUI()
  }
  
  // MARK: - UI
  private func setupUI() {
    setupCollectionView()
  }
  
  private func setupCollectionView() {
    collectionView.registerNib(UINib(nibName: "ThumbnailCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ThumbnailCollectionViewCell")
    collectionView.dataSource = self
    collectionView.delegate = self
  }
  
  // MARK: - UICollectionViewDataSource, UICollectionViewDelegate
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return file_Array.count
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ThumbnailCollectionViewCell", forIndexPath: indexPath) as! ThumbnailCollectionViewCell
    cell.bindImageView(image_Array[indexPath.row], pathExtension: file_Array[indexPath.row].pathExtension!.lowercaseString
)
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    imageView.image = image_Array[indexPath.row]
    let pathExtension = file_Array[indexPath.row].pathExtension!.lowercaseString
    if pathExtension == "mov" {
      playVideo(file_Array[indexPath.row])
    }
  }
  
  // MARK: - Utilities
  private func loadImagesAndVideos() {
    let documentPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    do {
      let properties = [NSURLLocalizedNameKey, NSURLCreationDateKey, NSURLContentModificationDateKey, NSURLLocalizedTypeDescriptionKey]
      let url_Array: [NSURL] = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(NSURL(fileURLWithPath: documentPath), includingPropertiesForKeys: properties, options: .SkipsHiddenFiles)
      file_Array = url_Array.filter({ (url) -> Bool in
        let pathExtension = url.pathExtension!.lowercaseString
        return (pathExtension == "png" || pathExtension == "jpg" || pathExtension == "mov")
      })
      file_Array.sortInPlace({ (url1, url2) -> Bool in
        var attributes_Dictionary1 = [:]
        var attributes_Dictionary2 = [:]
        do {
          attributes_Dictionary1 = try url1.resourceValuesForKeys(properties)
          attributes_Dictionary2 = try url2.resourceValuesForKeys(properties)
        } catch {}
        return (attributes_Dictionary1[NSURLCreationDateKey] as! NSDate).compare((attributes_Dictionary2[NSURLCreationDateKey] as! NSDate)) == NSComparisonResult.OrderedAscending
      })
      for url in file_Array {
        getImage(url.path!)
      }
    } catch {}
  }
  
  private func getImage(filePath: String) {
    let pathExtension = (filePath as NSString).pathExtension.lowercaseString
    switch pathExtension {
    case "png", "jpg":
      image_Array.append(UIImage(contentsOfFile: filePath)!)
    case "mov":
      let avPlayer = AVPlayer(URL: NSURL(fileURLWithPath: filePath))
      let avAsset = avPlayer.currentItem?.asset
      let imageGenerator = AVAssetImageGenerator(asset: avAsset!)
      imageGenerator.maximumSize = imageView.frame.size
      imageGenerator.appliesPreferredTrackTransform = true // 取得正確方向的截圖
      var actualTime: CMTime = kCMTimeZero
      do {
        let cgImageRef = try imageGenerator.copyCGImageAtTime(avPlayer.currentTime(), actualTime: &actualTime)
        image_Array.append(UIImage(CGImage: cgImageRef))
      } catch let error as NSError {
        print("getImage error: \(error)")
      }
    default: break
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
}
