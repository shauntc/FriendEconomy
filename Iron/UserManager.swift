//
//  UserManager.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-24.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit
import Firebase

class UserManager: NSObject {
    
    static let shared = UserManager()
    
    var currentUser:User?{
        willSet{stopObserving(user:currentUser, handle:observationHandle)}
        didSet{observeCurrentUser()}
    }
    var observationHandle:FIRDatabaseHandle?
    
    private let internalQueue:DispatchQueue
    
    
    //MARK - Public Interface
    func newUser(name:String, email:String, password:String, completion:@escaping (_ user:User?, _ error:Error?) -> () ) {
        internalQueue.async {
            FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(nil, error)
                        return
                    }
                }
                guard let user = user else {
                    print(Iron.ErrorMessages.root + "No user returned from Firebase despite lack of error")
                    return
                }
                let newUser = User(firUser: user, name: name, groups: [], friends: [], groupIDs: [], friendIDs: [])
                self.currentUser = newUser
                self.attachToFirebase(user: newUser)
                
                DispatchQueue.main.async {
                    completion(newUser, error)
                }
                
            })
            
        }
    }
    
    func logInCurrentUser() {
        internalQueue.async {
            guard let currentUser = FIRAuth.auth()?.currentUser else {
                print(Iron.ErrorMessages.root + "No current user")
                return
            }
            
            let user = User(firUser: currentUser, name: "placeholder", groups: [], friends: [], groupIDs: [], friendIDs: [])
            self.currentUser = user
        }
    }
    
    
    //MARK: - PRIVATE FUNCTIONS
    
    private func attachToFirebase(user:User) {
        let ref = Iron.DatabaseRefrence.users.child(user.firUser.uid)
        
        ref.setValue(formatUser(user: user))
    }
    
    //MARK: - Observation
    private func observeCurrentUser(){
        internalQueue.async{
            guard let currentUser = self.currentUser else{
                print(Iron.ErrorMessages.root + "No current user")
                return
            }
            
            let ref = Iron.DatabaseRefrence.users.child(currentUser.firUser.uid)
            
            self.observationHandle = ref.observe(.value, with:{ [weak self] (dataSnapshot) in
                guard let data:NSDictionary = dataSnapshot.value as? NSDictionary else {
                    print(Iron.ErrorMessages.root + "Could not be read as a dictionary")
                    return
                }
                
                self?.parseFirbaseDataToUser(data: data)
                })
        }
    }
    
    private func stopObserving(user:User?, handle:FIRDatabaseHandle?){
        internalQueue.async {
            guard  let user = user, let handle = handle else {
                print(Iron.ErrorMessages.root + "No current user or no current handle")
                return
            }
            
            let ref = Iron.DatabaseRefrence.users.child(user.firUser.uid)
            ref.removeObserver(withHandle: handle)
        }
    }
    
    //MARK: - Firebase data formatting
    private func parseFirbaseDataToUser(data:NSDictionary){
        guard let currentUser = self.currentUser else {
            return
        }
        
        if let name = data[userKeys.name] as? String {
            currentUser.name = name
        }
        
        //Lets observers know that user has been updated
        let notification = Notification(name: Notifications.currentUserUpdated, object: currentUser)
        NotificationCenter.default.post(notification)
        
        
        //Tells Friend/Group manager to update
        if let friendIDs = data[userKeys.friends] as? NSDictionary  {
            var friendIDArray = [String]()
            for (friendID, _) in friendIDs {
                friendIDArray.append(friendID as! String)
            }
            
            FriendManager.shared.update(user:currentUser, newIDs:friendIDArray)
        }
        
        if let groupIDs = data[userKeys.groups] as? NSDictionary {
            
            var groupIDArray = [String]()
            for (groupID, _) in groupIDs {
                groupIDArray.append(groupID as! String)
            }
            
            GroupManager.shared.update(user:currentUser, newIDs:groupIDArray)
        }
    }

    private func formatUser(user:User) -> Dictionary<NSString, Any>{
        var fbDictionary:Dictionary<NSString,Any> = [userKeys.name:user.name as NSString]
        
        let friendsArray = NSMutableArray()
        for friend in user.friends {
            friendsArray.add(friend.uid as NSString)
        }
        
        fbDictionary[userKeys.friends] = friendsArray

        
        let groupsArray = NSMutableArray()
        for group in user.groups {
            groupsArray.add(group.gid as NSString)
        }
        
        fbDictionary[userKeys.groups] = groupsArray
        
        return fbDictionary
    }
    
    //MARK: - Initializers
    
    override init() {
        self.internalQueue = DispatchQueue(label:"com.shauntc.iron.user")
    }
    
    //MARK: - Private Constants
    private struct userKeys {
        static let friends = "friends" as NSString
        static let name = "name" as NSString
        static let groups = "groups" as NSString
        //add key names for new properties here
    }
    
    
    //MARK: - Notification Constants
    struct Notifications {
        static let currentUserUpdated = Notification.Name("CurrentUserUpdated")
    }
}
