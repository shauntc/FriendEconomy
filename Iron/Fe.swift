//
//  Iron.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-19.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit
import Firebase

struct Iron {
    
    struct DatabaseRefrence {
        static let root = FIRDatabase.database().reference()
        static let users = Iron.DatabaseRefrence.root.child("users")
        static let groups = Iron.DatabaseRefrence.root.child("groups")
        static let bills = Iron.DatabaseRefrence.root.child("bills")
        static let payments = Iron.DatabaseRefrence.root.child("payments")
    }
    
    struct ErrorMessages {
        static let root = "IRON_ERROR: "
        static let status = "IRON_STATUS: " 
    }

}
