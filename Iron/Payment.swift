//
//  Payment.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-18.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit

class Payment: NSObject {
    
    var user:User
    var amount:Float
    var pid:String
    
    init(user:User, amount:Float, paymentID:String){
        self.user = user
        self.amount = amount
        self.pid = paymentID
    }

}
