//
//  UIImageView+extension.swift
//  AHDataGenerator
//
//  Created by Andy Hurricane on 3/29/17.
//  Copyright © 2017 Andy Hurricane. All rights reserved.
//

import UIKit

extension UIImageView {
    func AH_setImage(urlStr: String, completion: ((_ image: UIImage?) -> Swift.Void)?){
        AHNetowrkTool.tool.requestImage(urlStr: urlStr) { (image) in
            if image != nil {
                if completion != nil {
                    // if there's a completion, then let the end user to decide how to use the image
                    completion!(image)
                }else {
                    self.image = image!
                }
                
                return
            }
            completion?(nil)
        }
    }
    func AH_setImage(urlStr: String){
        AH_setImage(urlStr: urlStr, completion: nil)
    }
}
