//
//  ThumbnailCollectionViewCell.swift
//  camera-swift
//
//  Created by Han Chen on 2016/9/8.
//  Copyright © 2016年 Han Chen. All rights reserved.
//

import Foundation
import UIKit

class ThumbnailCollectionViewCell: UICollectionViewCell {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var sign_View: UIView!
  @IBOutlet weak var sign_Label: UILabel!
  
  override func awakeFromNib() {
    
  }
  
  func bindImageView(image: UIImage, pathExtension: String) {
    imageView.image = image
    switch pathExtension {
    case "png":
      sign_View.backgroundColor = UIColor(red: 61/255, green: 145/255, blue: 163/255, alpha: 0.6)
    case "jpg":
      sign_View.backgroundColor = UIColor(red: 220/255, green: 80/255, blue: 33/255, alpha: 0.6)
    case "mov":
      sign_View.backgroundColor = UIColor(red: 100/255, green: 187/255, blue: 150/255, alpha: 0.6)
    default: break
    }
    sign_Label.text = pathExtension.uppercaseString
  }
}
