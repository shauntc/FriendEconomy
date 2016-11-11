//
//  UIFont+ApplicationFonts.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-21.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit

extension UIFont {
    class func iron_receiptFont(size: CGFloat) -> UIFont {
        let font = UIFont(name: "MerchantCopy", size: size)
        if let font = font {
            return font
        }else{
            print("Error retrieving receipt font")
            return UIFont.systemFont(ofSize: size)
        }
    }
}
