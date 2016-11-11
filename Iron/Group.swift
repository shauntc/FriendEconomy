//
//  Group.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-17.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit
import Firebase

class Group: NSObject {
    
    //MARK: - Firebase Properties
    var gid:String
    var name:String
    var memberIDs:[String]
    
    //MARK: - Local Properties
    var currentUserPayments:[Payment]?
    var bills:[Bill]? {
        get{return sortedBills}
        set (newValue) { sortedBills = newValue?.sorted(by: {$0.date > $1.date})}
    }
    fileprivate var sortedBills:[Bill]?
        
    //MARK: - Computed Properties
    var currentUserBalance:Float? {
        get {
            if let payments = currentUserPayments {
                var total:Float = 0
                for payment in payments {
                    total += payment.amount
                }
                return total
            }
            return nil
        }
    }
    
    var members:[Friend]?{
        get{
            if let userFriends = UserManager.shared.currentUser?.friends {
                var members = [Friend]()
                let ids = Set(memberIDs)
                for friend in userFriends {
                    if ids.contains(friend.uid){
                        members.append(friend)
                    }
                }
                return members
            }else{
                return nil
            }
        }
    }
    
    //MARK: - Initializer
    init(groupID:String, name:String, memberIDs:[String]) {
        self.gid = groupID
        self.name = name
        self.memberIDs = memberIDs
    }
}
