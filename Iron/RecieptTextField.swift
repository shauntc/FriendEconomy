//
//  RecieptTextField.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-11-02.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit

class RecieptTextField: UITextField {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.font = UIFont.iron_receiptFont(size: 20)
        self.textColor = .iron_receiptBlue
        self.borderStyle = .line
        self.layer.borderColor = UIColor.iron_receiptBlue.cgColor
    }
}
