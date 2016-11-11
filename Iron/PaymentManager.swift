//
//  PaymentManager.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-25.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit
import Firebase

class PaymentManager: NSObject {
    
    static let shared = PaymentManager()
    private let internalQueue:DispatchQueue
    private var observationHandles = Dictionary<GroupMember, FIRDatabaseHandle>()
    private var userPayingCheckHandle:FIRDatabaseHandle?

    
    func retrievePayments(group:Group, user:User) {
        internalQueue.async {
            let ref = Iron.DatabaseRefrence.payments.child(group.gid).child(user.firUser.uid)
            ref.observeSingleEvent(of: .value, with: { [weak self] (dataSnapshot) in
                guard let paymentsDictionary = dataSnapshot.value as? NSDictionary else {
                    print(Iron.ErrorMessages.root + "No payments dictionary recieved")
                    return
                }
                
                self?.parse(dictionary:paymentsDictionary, toGroup:group, andUser:user)
            })
            
        }
    }
    
    func monitorPayments(group:Group, user:User) {
        internalQueue.async {
            
            self.checkIsUserPaying(group: group, user: user)
            
            let ref = Iron.DatabaseRefrence.payments.child(group.gid).child(user.firUser.uid)
            
            let databaseHandle = ref.observe(.value, with: { [weak self] (dataSnapshot) in
                guard let paymentsDictionary = dataSnapshot.value as? NSDictionary else {
                    print(Iron.ErrorMessages.root + "No payments dictionary recieved")
                    return
                }
                
                self?.parse(dictionary:paymentsDictionary, toGroup:group, andUser:user)
            })
            
            self.observationHandles[GroupMember(group: group, user: user)] = databaseHandle
            
        }
    }
    
    func stopMonitoringPayments(group:Group, user:User) {
        internalQueue.async {
            let groupMember = GroupMember(group:group, user:user)
            if let databaseHandle = self.observationHandles[groupMember], let userPayingCheckHandle = self.userPayingCheckHandle {
                let ref = Iron.DatabaseRefrence.payments.child(group.gid).child(user.firUser.uid)
                ref.removeObserver(withHandle: databaseHandle)
                ref.removeObserver(withHandle: userPayingCheckHandle)
                self.observationHandles.removeValue(forKey: groupMember)
                self.userPayingCheckHandle = nil
            }
        }
    }
    
    func generatePayments(bill:Bill) {internalQueue.async {
        let ref = Iron.DatabaseRefrence.payments.child(bill.group.gid)
        
        ref.observeSingleEvent(of: .value, with: { (dataSnapshot) in
            guard let payments = dataSnapshot.value as? NSDictionary else{
                print(Iron.ErrorMessages.root + "Payments dont have the correct format")
                return
            }
            
            var lowestBalance:(balance:Float, uid:String) = (0, "")
            
            if let currentBallance = bill.group.currentUserBalance, let currentUID = FIRAuth.auth()?.currentUser?.uid {
                lowestBalance = (currentBallance, currentUID)
            }
            
            var set = Set<String>()
            for uid in bill.userIDs {
                set.insert(uid)
            }
            
            for (uid, userPayments) in payments {
                if set.contains(uid as! String) {
                    if let userPayments = userPayments as? NSDictionary {
                        var paymentsTotal:Float = 0
                        for (_, paymentValue) in userPayments {
                            if let paymentValue = paymentValue as? Float {
                                paymentsTotal += paymentValue
                            }else {
                                print(Iron.ErrorMessages.root + "payment not recognized as float")
                            }
                        }
                        
                        if paymentsTotal <= lowestBalance.balance {
                            lowestBalance.balance = paymentsTotal
                            lowestBalance.uid = uid as! String
                        }
                    }
                }
            }
        
            var finalPayments = [Float]()
            let paymentAmount = bill.amount / Float(bill.userIDs.count)
            
            for uid in bill.userIDs {
                if uid == lowestBalance.uid {
                    finalPayments.append(bill.amount - paymentAmount)
                }else {
                    finalPayments.append(-paymentAmount)
                }
            }
            
            self.sendToFirebase(bill: bill, paymentValues: finalPayments)
        })
    }}
    
    //MARK: - Private Functions
    private func parse(dictionary:NSDictionary, toGroup group:Group, andUser user:User) {
        var paymentsArray = [Payment]()
        for (paymentID, paymentValue) in dictionary {
            if let paymentID = paymentID as? String, let paymentValue = paymentValue as? Float {
                paymentsArray.append(Payment(user: user, amount: paymentValue, paymentID: paymentID))
            }
        }
        
        group.currentUserPayments = paymentsArray
        
        NotificationCenter.default.post(Notification(name: Notifications.paymentsUpdatedOnGroup, object: (group, user), userInfo: nil))
    }
    
    private func sendToFirebase(bill:Bill, paymentValues:[Float]){
        var safeAccessPID:[String] {
            set (newValue) {self.internalQueue.sync {bill.paymentIDs = newValue}}
            get{return self.internalQueue.sync {bill.paymentIDs}}
        }
        
        for (index, uid) in bill.userIDs.enumerated() {
            
            let ref = Iron.DatabaseRefrence.payments.child(bill.group.gid).child(uid).childByAutoId()
            safeAccessPID.append(ref.key)
            ref.setValue(paymentValues[index])
            
        }
        
        BillManager.shared.sendToFirebase(bill: bill)
    }
    
    private func checkIsUserPaying(group:Group, user:User) {
        var initialDataLoad = false
        let ref = Iron.DatabaseRefrence.payments.child(group.gid).child(user.firUser.uid)
        
        userPayingCheckHandle = ref.observe(.childAdded, with: { (dataSnapshot) in
            
            guard initialDataLoad else {
                //first data has not loaded yet, so do not check if this person is paying
                return
            }
            
            guard let paymentValue = dataSnapshot.value as? Float else {
                print(Iron.ErrorMessages.root + "No payments dictionary recieved")
                return
            }
            
            
            if paymentValue >= 0 {
                NotificationCenter.default.post(Notification(name: Notifications.userIsPaying))
            }
            
        })
        
        ref.observeSingleEvent(of: .value, with: {(dataSnapshot) in
            initialDataLoad = true
        })
        
        
    }
    
    //MARK: - Notification Names
    struct Notifications {
        static let paymentsUpdatedOnGroup = Notification.Name("PaymentsUpdatedOnGroup")
        static let userIsPaying = Notification.Name("UserIsPaying")
    }
    
    //MARK: - Hashable Struct for dictionary
    private struct GroupMember : Hashable, Equatable {
        
        var hashValue: Int {
            return group.hashValue ^ user.hashValue
        }
        
        let group:Group
        let user:User
        
        static func ==(lhs:GroupMember, rhs:GroupMember) -> Bool {
            return lhs.group == rhs.group && lhs.user == rhs.user
        }
        
        
        init(group:Group, user:User) {
            self.group = group
            self.user = user
        }
    }
    
    //MARK: - Initializer
    override init() {
        self.internalQueue = DispatchQueue(label: "com.shauntc.iron.payment")
    }
    
}
