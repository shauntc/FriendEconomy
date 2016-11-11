//
//  User.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-17.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit
import Firebase

class User: NSObject {

    let firUser:FIRUser
    var name:String
    var groups:[Group]
    var groupIDs:[String]
    var friends:[Friend]
    var friendIDs:[String]
    
    func addFriend(){
        
    }
    
    func addGroup(){
        
    }
    
    init(firUser:FIRUser, name:String, groups:[Group], friends:[Friend], groupIDs:[String], friendIDs:[String]) {
        self.firUser = firUser
        self.name = name
        self.groups = groups
        self.groupIDs = groupIDs
        self.friends = friends
        self.friendIDs = friendIDs
    }
    
}
