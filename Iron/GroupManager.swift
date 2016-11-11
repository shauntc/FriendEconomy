//
//  GroupManager.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-25.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit
import Firebase

class GroupManager: NSObject {
    
    static let shared = GroupManager()
    private let internalQueue: DispatchQueue
    private var updateHandles = Dictionary<Group,FIRDatabaseHandle>()
    
    //MARK: - Public Interface
    
    func update(user:User, newIDs:[String]) {
        internalQueue.async {
            
            var newGroups = [Group]()
            var userControledAccess: [Group] {
                set (newValue) {self.internalQueue.sync {newGroups = newValue}}
                get{return self.internalQueue.sync {newGroups}}
            }
            
            let userGroupsUpdate = DispatchGroup()
            
            DispatchQueue.concurrentPerform(iterations: newIDs.count, execute: { [weak self] (count) in
                userGroupsUpdate.enter()
                
                self?.fetch(groupID: newIDs[count], completion: { (fetchedGroup) in
                    guard let fetchedGroup = fetchedGroup else {
                        userGroupsUpdate.leave()
                        return
                    }
                    userControledAccess.append(fetchedGroup)
                    userGroupsUpdate.leave()
                })
                
                })
            
            userGroupsUpdate.notify(queue: self.internalQueue, execute: {
                user.groups = newGroups
                user.groupIDs = newIDs
                NotificationCenter.default.post(name: Notifications.userGroupsUpdated, object: user)
            })
            
        }
    }
    
    func retrieve(groupID:String, completion:@escaping (Group?)->()){
        internalQueue.async {
            let ref = Iron.DatabaseRefrence.groups.child(groupID)
            
            ref.observe(.value, with: { [weak self] (dataSnapshot) in
                guard let dataDictionary = dataSnapshot.value as? NSDictionary else {
                    print(Iron.ErrorMessages.root + "Unable to read group dictionary")
                    completion(nil)
                    return
                }
                
                let group = self?.parse(dictionary: dataDictionary, groupID: groupID)
                
                completion(group)
            })
            
            
            
        }
    }
    
    
    func monitorUpdatesTo(group:Group) {
        internalQueue.async {
            if let user = UserManager.shared.currentUser {
                PaymentManager.shared.monitorPayments(group: group, user: user)
            }
            
            //Start Bill Updates
            BillManager.shared.monitorBills(group: group)
            
            let ref = Iron.DatabaseRefrence.groups.child(group.gid)
            
            self.updateHandles[group] = ref.observe(.value, with: { [weak self] (dataSnapshot) in
                guard let dataDictionary = dataSnapshot.value as? NSDictionary else {
                    print(Iron.ErrorMessages.root + "Unable to read group dictionary")
                    return
                }
                
                self?.update(group: group, fromDictionary: dataDictionary)
                
                NotificationCenter.default.post(name: Notifications.groupUpdated, object: group)
                })
        }
    }
    
    func stopUpdatesTo(group:Group){
        internalQueue.async {
            BillManager.shared.stopUpdates(group:group)
            
            if let user = UserManager.shared.currentUser {
                PaymentManager.shared.stopMonitoringPayments(group: group, user: user)
            }
            if let updateHandle = self.updateHandles[group] {
                let ref = Iron.DatabaseRefrence.groups.child(group.gid)
                ref.removeObserver(withHandle: updateHandle)
                self.updateHandles.removeValue(forKey: group)
            }
        }
    }
    
    //MARK: - Private Functions
    
    private func fetch(groupID:String, completion:@escaping (Group?) -> () ) {
        
        
        
        let ref = Iron.DatabaseRefrence.groups.child(groupID)
        
        ref.observeSingleEvent(of: .value, with: { (dataSnapshot) in
            guard let dataDictionary = dataSnapshot.value as? NSDictionary else {
                print(Iron.ErrorMessages.root + "Unable to read group dictionary")
                return
            }
            
            let group = self.parse(dictionary: dataDictionary, groupID: groupID)
            
            if let user = UserManager.shared.currentUser {
                PaymentManager.shared.retrievePayments(group: group, user: user)
            }
            
            completion(group)
        })
    }
    
    private func parse(dictionary: NSDictionary, groupID:String) -> Group {
        
        var name = ""
        var memberIDs = [String]()
        
        
        if let fbName = dictionary[GroupKeys.name] as? String {
            name = fbName
        }
        if let fbMemberIDs = dictionary[GroupKeys.members] as? NSDictionary {
            
            for (memberID, _) in fbMemberIDs {
                memberIDs.append(memberID as! String)
            }
            
        }
     
        
        
        return Group(groupID: groupID, name: name, memberIDs: memberIDs)
    }

    private func update(group:Group, fromDictionary dictionary:NSDictionary) {
        let tempGroup = parse(dictionary: dictionary, groupID: group.gid)
        
        group.name = tempGroup.name
        group.memberIDs = tempGroup.memberIDs
        
    }
    
    
    //MARK: - Notification Reactions
    
    @objc private func paymentsUpdated(notification:Notification) {
        guard let groupMember = notification.object as? (group:Group, user:User) else {
            print(Iron.ErrorMessages.root + "No group member provided with notification")
            return
        }
        
        NotificationCenter.default.post(name: Notifications.groupUpdated, object: groupMember.group)
    }
    
    @objc private func billsUpdated(notification:Notification) {
        //MARK: fill with bill based updates if necessary
    }
    
    //MARK: - Database Key values
    
    private struct GroupKeys {
        static let name = "name"
        static let members = "users"
    }
    
    //MARK: - Notification Names
    
    struct Notifications {
        static let groupUpdated = Notification.Name("GroupUpdated")
        static let userGroupsUpdated = Notification.Name("UserGroupsUpdated")
    }
    
    //MARK: - Initialization method
    
    override init() {
        self.internalQueue = DispatchQueue(label: "com.shauntc.iron.group")
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(paymentsUpdated(notification:)), name: PaymentManager.Notifications.paymentsUpdatedOnGroup, object: nil)
    }
}
