//
//  FriendManager.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-25.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit
import Firebase

class FriendManager: NSObject {

    static let shared = FriendManager()
    private let internalQueue:DispatchQueue
//    private var updateHandlers: Dictionary<Friend, FIRDatabaseHandle> {
//        set (newValue) {internalQueue.sync {self.updateHandlers = newValue}}
//        get {return internalQueue.sync {self.updateHandlers}}
//    }

    
    func update(user:User, newIDs:[String]) {
        internalQueue.async {
        
            var newFriends = [Friend]()
            var userControledAccess: [Friend] {
                set (newValue) {self.internalQueue.sync {newFriends = newValue}}
                get{return self.internalQueue.sync {newFriends}}
            }
            
            let userFriendUpdates = DispatchGroup()
            
            DispatchQueue.concurrentPerform(iterations: newIDs.count, execute: { [weak self] (count) in
                userFriendUpdates.enter()
                
                self?.fetch(userID: newIDs[count], completion: { (fetchedFriend) in
                    guard let fetchedFriend = fetchedFriend else {
                        userFriendUpdates.leave()
                        return
                    }
                    userControledAccess.append(fetchedFriend)
                    userFriendUpdates.leave()
                })
                
            })
            
            userFriendUpdates.notify(queue: self.internalQueue, execute: {
                user.friends = newFriends
                user.friendIDs = newIDs
                NotificationCenter.default.post(name: Notifications.friendListUpdated, object: user)
            })
        }
    }
    
    //MARK: - Fetch

    private func fetch(userID:String, completion: @escaping (Friend?) -> () ) {
        Iron.DatabaseRefrence.users.child(userID).child(FriendKeys.name).observeSingleEvent(of:.value, with: { (dataSnap) in
            guard let friendName = dataSnap.value as? String else {
                completion(nil)
                return
            }
            
            let newFriend = Friend(uid: userID, name: friendName)
            completion(newFriend)
        })
        
        
    }


    private struct FriendKeys {
        static let name = "name"
    }

    struct Notifications {
        static let friendUpdated = Notification.Name("FriendUpdated")
        static let friendListUpdated = Notification.Name("FriendListUpdated")
    }
    
    //MARK: - Initialization method
    
    override init() {
        self.internalQueue = DispatchQueue(label: "com.shauntc.iron.friend")
    }
    
}
