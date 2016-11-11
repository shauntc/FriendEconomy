//
//  BillCell.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-18.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit
import Firebase

class BillCell: UITableViewCell {

    @IBOutlet weak var paidAmountLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var shareLabel: RecieptLabel!
    @IBOutlet weak var usersLabel: RecieptLabel!
    @IBOutlet weak var backgrounImageView: UIImageView!
    
    
    
    var bill:Bill? {
        didSet{
            guard let bill = bill else{
                return;
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateLabel.text = "on " + dateFormatter.string(from: bill.date)

            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency
            
            titleLabel.text = bill.title
            
            if let userAmount = bill.currentUserPayment?.amount {
                paidAmountLabel.text = numberFormatter.string(from: userAmount as NSNumber)
            }else{
                paidAmountLabel.text = numberFormatter.string(from: 0 as NSNumber)
            }
            
            totalAmountLabel.text = numberFormatter.string(from: bill.amount as NSNumber)
            
            let share = bill.amount / Float(bill.userIDs.count)
            
            var users = ""
            
            if bill.userIDs.contains(UserManager.shared.currentUser!.firUser.uid) {
                shareLabel.text = numberFormatter.string(from: share as NSNumber)
                users += "me, "
            }else {
                shareLabel.text = numberFormatter.string(from: 0 as NSNumber)
            }
            
            if let presentMembers = bill.presentMembers {
                
                for (index, member) in presentMembers.enumerated() {
                    users += member.name
                    
                    if index < presentMembers.count - 1 {
                        users += ", "
                    }
                }
            }
            
            usersLabel.text = users
            
            shadow(view: backgrounImageView)
            
            
            
        }
    }
    
    fileprivate func shadow(view: UIView) {
        view.layer.shadowColor = UIColor.darkGray.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 1.0
        view.clipsToBounds = false
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
