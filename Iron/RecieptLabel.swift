//
//  RecieptLabel.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-21.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit

class RecieptLabel: UILabel {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.font = UIFont.iron_receiptFont(size: font.pointSize)
        self.textColor = .darkText
    }

}
