//
//  BillManager.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-24.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit
import Firebase

class BillManager: NSObject {
    static let shared = BillManager()
    private let internalQueue:DispatchQueue
    private var observationHandles = Dictionary<Group, FIRDatabaseHandle>()
    
    func monitorBills(group:Group) {
        let ref = Iron.DatabaseRefrence.bills.child(group.gid)
        
        let observationHandle = ref.observe(.value,  with:{ [weak self] (dataSnapshot) in
            guard let billsDictionary = dataSnapshot.value as? NSDictionary else {
                print(Iron.ErrorMessages.root + "No payments dictionary recieved")
                return
            }
            
            self?.parse(dictionary:billsDictionary, toGroup:group)
        })
        
        observationHandles[group] = observationHandle
    }
    
    func stopUpdates(group:Group) {
        internalQueue.async {
            if let updateHandle = self.observationHandles[group] {
                let ref = Iron.DatabaseRefrence.bills.child(group.gid)
                ref.removeObserver(withHandle: updateHandle)
            }
        }
    }
    
    func addBill(group:Group, amount:Float, otherUsers friends:[Friend], title:String, date:Date) {
        internalQueue.async {
            
            let ref = Iron.DatabaseRefrence.bills.child(group.gid).childByAutoId()
            let billID = ref.key
            
            var userIDs = [UserManager.shared.currentUser!.firUser.uid]
            for friend in friends {
                userIDs.append(friend.uid)
            }
            
            let newBill = Bill(billID: billID, title: title, amount: amount, userIDs: userIDs, paymentIDs: [String](), date: date, group: group)
            
            PaymentManager.shared.generatePayments(bill:newBill)
            
            group.bills?.append(newBill)
        }
    }
    
    func sendToFirebase(bill: Bill) {internalQueue.async {
        let ref = Iron.DatabaseRefrence.bills.child(bill.group.gid).child(bill.billID)
        ref.setValue(self.firebaseDictionary(bill: bill))
        }}
    
    func deleteBill(bill:Bill) {
        Iron.DatabaseRefrence.bills.child(bill.group.gid).child(bill.billID).removeValue()
        
        let ref = Iron.DatabaseRefrence.payments.child(bill.group.gid)
        
        for uid in bill.userIDs {
            for pid in bill.paymentIDs {
                ref.child(uid).child(pid).removeValue()
            }
        }
        
    }
    
    //MARK: - Private Functions
    
    private func firebaseDictionary(bill:Bill) -> NSDictionary {
        let firebaseDictionary = NSMutableDictionary()
        
        
        firebaseDictionary.setValue(bill.amount, forKey: BillKeys.amount)
        firebaseDictionary.setValue(bill.date.timeIntervalSince1970, forKey: BillKeys.date)
        firebaseDictionary.setValue(bill.title as NSString, forKey: BillKeys.name)
        
        let paymentDictionary = NSMutableDictionary()
        for paymentID in bill.paymentIDs {
            paymentDictionary.setValue(true, forKey: paymentID)
        }
        firebaseDictionary.setValue(paymentDictionary, forKey: BillKeys.payments)
        
        let userDictionary = NSMutableDictionary()
        for userID in bill.userIDs {
            userDictionary.setValue(true, forKey: userID)
        }
        firebaseDictionary.setValue(userDictionary, forKey: BillKeys.users)
        
        return firebaseDictionary
    }
    
    private func parse(dictionary:NSDictionary, toGroup group:Group) {
        
        var newBills = [Bill]()
        
        for (billID, billDict) in dictionary {
            guard let billID = billID as? String, let billDict = billDict as? NSDictionary else {
                print(Iron.ErrorMessages.root + "Bill Dictionary Parsing error")
                return
            }
            
            
            var name = ""
            var amount:Float = 0
            var userIDs = [String]()
            var paymentIDs = [String]()
            var date = Date()
            
            if let fbName = billDict[BillKeys.name] as? String {
                name = fbName
            }
            
            if let fbAmount = billDict[BillKeys.amount] as? Float {
                amount = fbAmount
            }
            
            if let fbUserIDs = billDict[BillKeys.users] as? NSDictionary {
                for (userID, _) in fbUserIDs {
                    if let userID = userID as? String {
                        userIDs.append(userID)
                    }
                }
            }
            
            if let fbPayments = billDict[BillKeys.payments] as? NSDictionary {
                for (billID, _) in fbPayments {
                    if let billID = billID as? String {
                        paymentIDs.append(billID)
                    }
                }
            }
            
            if let fbDate = billDict[BillKeys.date] as? Int {
                date = Date(timeIntervalSince1970: TimeInterval(fbDate))
            }
            
            let newBill = Bill(billID: billID, title: name, amount: amount, userIDs: userIDs, paymentIDs: paymentIDs, date: date, group:group)
            
            newBills.append(newBill)
        }
        
        group.bills = newBills
        
        NotificationCenter.default.post(name: Notifications.groupBillsUpdated, object: group)
    }
    
    //MARK: - Database Keys
    private struct BillKeys {
        static let name = "title"
        static let amount = "amount"
        static let users = "users"
        static let payments = "payments"
        static let date = "date"
        
    }
    
    //MARK: - Notification Names
    struct Notifications {
        static let groupBillsUpdated = Notification.Name("GroupBillsUpdated")
    }
    
    //MARK: - Initializer
    override init() {
        self.internalQueue = DispatchQueue(label: "com.shauntc.iron.bill")
    }
}
