//
//  Bill.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-17.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit
import Firebase

class Bill: NSObject {

    //MARK: - Firebase Properties
    let billID:String
    var title:String
    var amount:Float
    let date:Date
    var paymentIDs:[String]
    var userIDs:[String]

    
    
    //MARK: - Local Properties
    var currentUserPayment:Payment? {
        get{
            if let currentUserPayments = group.currentUserPayments {
                
                let ids = Set(paymentIDs)
                
                for payment in currentUserPayments {
                    if ids.contains(payment.pid) {
                        return payment
                    }
                }
            }
            return nil
        }
    }
    var group:Group
    var presentMembers:[Friend]? {
        get{
            if let groupFriends = group.members {
                var friends = [Friend]()
                let ids = Set(userIDs)
                for friend in groupFriends {
                    if ids.contains(friend.uid){
                        friends.append(friend)
                    }
                }
                return friends
            }else{
                return nil
            }
        }
    }
    
    
    //MARK: - Initializer

    init(billID:String, title:String, amount:Float, userIDs:[String], paymentIDs:[String], date:Date, group:Group) {
        self.billID = billID
        self.title = title
        self.amount = amount
        self.paymentIDs = paymentIDs
        self.date = date
        self.group = group
        self.userIDs = userIDs
    }
}
