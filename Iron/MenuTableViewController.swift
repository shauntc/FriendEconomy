//
//  MenuTableViewController.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-11-03.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit

class MenuTableViewController: UITableViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var friendImageView: UIImageView!
    @IBOutlet weak var groupsLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var numFriendsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        avatarImageView.layer.cornerRadius = avatarImageView.frame.height/2

        
        
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let user = UserManager.shared.currentUser {
            usernameLabel.text = user.name
            
/*
            var groupNames = ""
            for (index, group) in user.groups.enumerated() {
                groupNames += group.name
                
                if index < user.groups.count - 1 {
                    groupNames += ", "
                }
            }
            groupsLabel.text = groupNames
 */
            if user.groups.count == 1 {
                groupsLabel.text = user.groups.count.description + " Group"
            }else{
                groupsLabel.text = user.groups.count.description + " Groups"
            }
            
            if user.friends.count == 1 {
                numFriendsLabel.text = user.friends.count.description + " Friend"
            }else{
                numFriendsLabel.text = user.friends.count.description + " Friends"
            }
            
        }
    }
    
    
    

}
