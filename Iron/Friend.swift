//
//  Friend.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-18.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit

class Friend: NSObject {

    let uid:String
    var name:String
    
    init(uid:String, name:String){
        self.uid = uid
        self.name = name
    }
}
