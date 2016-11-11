//
//  HomeViewController.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-18.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit
import UserNotifications

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    //MARK: - Properties
    
        //Doing this in the did set could be an issue if this is set from another view
    var displayedGroup:Group?{
        didSet{
            if let group = displayedGroup {
                self.groupView.configureView(group:group)
                GroupManager.shared.monitorUpdatesTo(group: group)
                
                //MARK: TESTING CODE
                print(Iron.ErrorMessages.status + "Getting Updates")
            }
        }
        willSet{
            if let group = displayedGroup {
                GroupManager.shared.stopUpdatesTo(group: group)
                
                //MARK: TESTING CODE
                print(Iron.ErrorMessages.status + "Stopping Updates")
            }
        }
    }
    
    var currentAddBillView: AddBillView?
    var currentBlurView:UIVisualEffectView?
    
    //MARK: - Storyboard Outlets
    @IBOutlet weak var groupView: GroupView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    //@IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    
    
    //MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeToUpdates()
        
        
    }
    
    //MARK: - Table View Data Source
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:BillCell = tableView .dequeueReusableCell(withIdentifier: "billCell", for: indexPath) as! BillCell
        
        if let displayedGroupBills = displayedGroup?.bills {
            cell.bill = displayedGroupBills[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let displayedGroupBills = displayedGroup?.bills {
            return displayedGroupBills.count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            BillManager.shared.deleteBill(bill: (displayedGroup?.bills?[indexPath.row])!)
        }
    }
    
    
    //MARK: - Update Notification Responses
    
    func userUpdated(notification:NSNotification){
        
        guard let user = notification.object as? User else {
            print(Iron.ErrorMessages.root + "No user sent with user updated notification")
            return
        }
        DispatchQueue.main.async{self.title = user.name}
    }
    
    func friendsUpdated(notification:Notification){
        guard let user = notification.object as? User else {
            print(Iron.ErrorMessages.root + "No user sent with friends list updated notification")
            return
        }
        
        //MARK: TESTING CODE
        DispatchQueue.main.async{self.tableView.reloadData()}
        
    }
    
    func groupsUpdated(notification:Notification) {
        guard let user = notification.object as? User else {
            print(Iron.ErrorMessages.root + "No user sent with groups list updated notification")
            return
        }
        
        //MARK: TESTING CODE
        if let firstGroup = user.groups.first {
            DispatchQueue.main.async{self.displayedGroup = firstGroup}
        }
    }
    
    func watchedGroupUpdated(notification:Notification) {
        guard let group = notification.object as? Group else {
            print(Iron.ErrorMessages.root + "Watched group notification didnt come with a group")
            return
        }
        
        if displayedGroup == group {
            DispatchQueue.main.async { [weak self] in
//                self?.tableView.reloadData()
                self?.groupView.configureView(group: group)
            }
        }else{
            print(Iron.ErrorMessages.root + "Returned group is not the displayed group")
        }
    }
    
    func groupBillsUpdated(notification:Notification) {
        guard  let group = notification.object as? Group else {
            print(Iron.ErrorMessages.root + "Group not sent with bills update notification")
            return
        }
        
        if let displayedGroup = displayedGroup {
            if displayedGroup == group {
                DispatchQueue.main.async {self.tableView.reloadData()}
            }
        }
    }
    
    func paymentsUpdated(notification:Notification) {
        tableView.reloadData()
    }
    
    func userIsPaying(notification:Notification) {
        if UIApplication.shared.applicationState == .active {
            presentAlert(title: "Your turn to pay", message: "")
        }else{
            let content = UNMutableNotificationContent()
            content.title = "It's your turn to pay"
            content.body = "You pay this time around"
            content.sound = UNNotificationSound.default()
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(floatLiteral: 1), repeats: false)
            
            let request = UNNotificationRequest(identifier: "com.shauntc.iron.userpays", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }
    
    
    //MARK: - Storyboard Actions
    
    @IBAction func addItemPressed(_ sender: AnyObject) {
        let addBillView = AddBillView(frame: CGRect(x: self.view.frame.width * (1/8), y: self.view.frame.height, width: self.view.frame.width * (3/4), height: self.view.frame.height * (3/4)))
        
        addBillView.group = displayedGroup
        addBillView.closeButton.addTarget(self, action: #selector(closeButtonPressed(sender:)), for: .touchUpInside)
        addBillView.addButton.addTarget(self, action: #selector(createBillButtonPressed(sender:)), for: .touchUpInside)

        currentAddBillView = addBillView
        
        presentOnBlur(view: addBillView)
    }
    
    func closeButtonPressed(sender: UIButton) {
        removePresentationOnBlurClose()
    }
    
    func createBillButtonPressed(sender: UIButton) {
        if let currentAddBillView = currentAddBillView {
            guard let group = currentAddBillView.group else {
                print(Iron.ErrorMessages.root + "No group attached to the add bill view")
                return
            }
            
            var users = [Friend]()
            
            if let indexPaths = currentAddBillView.tableView.indexPathsForSelectedRows {
                for indexPath in indexPaths {
                    users.append((group.members?[indexPath.row])!)
                }
            }
            
            guard let amount = Float(currentAddBillView.amountTextField.text!) else {
                print(Iron.ErrorMessages.root + "No amount entered")
                //MARK: PRESENT ERROR HERE
                return
            }
            
            var billTitle = ""
            if let enteredTitle = currentAddBillView.titleTextField.text {
                billTitle = enteredTitle
            }
            
            BillManager.shared.addBill(group: group , amount: amount , otherUsers: users, title: billTitle, date: Date())
        }
        
        removePresentationOnBlurCreate()
    }
    
    @IBAction func userProfilePressed(_ sender: Any) {
        
        guard let isLeftOpen = slideMenuController()?.isLeftOpen() else {
            return
        }
        
        
        
        if isLeftOpen {
            slideMenuController()?.closeLeft()
        }else {
            slideMenuController()?.openLeft()
        }
    }

    //MARK: - Visual Functions
    
    private func presentOnBlur(view:UIView) {
        
        let blurView = UIVisualEffectView()
        
        currentBlurView = blurView
        
        
        
        blurView.contentView.addSubview(view)
        
        let rootView = UIApplication.shared.keyWindow?.rootViewController?.view
        blurView.frame = (rootView?.bounds)!
        rootView?.addSubview(blurView)
        

        
        UIView.animate(withDuration: 1) {
            blurView.effect = UIBlurEffect(style: .dark)
            view.center = blurView.center
        }
    }
    
    private func removePresentationOnBlurClose() {
        
        
        UIView.animate(withDuration: 0.5, animations: {
            self.currentAddBillView?.alpha = 0.0
            self.currentBlurView?.effect = nil
        }, completion: {(success) in
            self.currentBlurView?.removeFromSuperview()
        })
    }
    
    private func removePresentationOnBlurCreate() {
        
        
        guard let billView = currentAddBillView else{
            return
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            billView.frame.origin = CGPoint(x: billView.frame.origin.x, y: -billView.frame.height)
            self.currentBlurView?.effect = nil
        }, completion: {(success) in
            self.currentBlurView?.removeFromSuperview()
        })
    }
    
    private func presentAlert(title:String, message:String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        UIApplication.shared.keyWindow?.rootViewController?.show(alert, sender: self)
    }
    
    //MARK: - Subscribed Notifications
    private func subscribeToUpdates() {
        NotificationCenter.default.addObserver(self, selector: #selector(userUpdated(notification:)), name: UserManager.Notifications.currentUserUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(friendsUpdated(notification:)), name: FriendManager.Notifications.friendListUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(groupsUpdated(notification:)), name: GroupManager.Notifications.userGroupsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(watchedGroupUpdated(notification:)), name: GroupManager.Notifications.groupUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(groupBillsUpdated(notification:)), name: BillManager.Notifications.groupBillsUpdated , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(paymentsUpdated(notification:)), name: PaymentManager.Notifications.paymentsUpdatedOnGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userIsPaying(notification:)), name: PaymentManager.Notifications.userIsPaying, object: nil)
    }

}
