//
//  GroupView.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-19.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit

class GroupView: UIView {

    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupName: UILabel!
    @IBOutlet weak var numInGroupLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var owedLabel: RecieptLabel!
    
    func configureView(group:Group){
        
        groupName.textColor = UIColor.iron_receiptBlue
        numInGroupLabel.textColor = UIColor.iron_receiptBlue
        balanceLabel.textColor = UIColor.iron_receiptBlue
        owedLabel.textColor = UIColor.iron_receiptBlue

        
        groupName.text = group.name
        
        if let members = group.members {
            var memberNames = ""
            
            for (index, member) in members.enumerated() {
                memberNames += member.name
                
                if index < members.count - 1 {
                    memberNames += ", "
                }
            }
            numInGroupLabel.text = memberNames
        }else {
            numInGroupLabel.text = group.memberIDs.count.description
        }

        if let balance = group.currentUserBalance {
            
            let currencyFormatter = NumberFormatter()
            
            currencyFormatter.numberStyle = .currency
            
            balanceLabel.text = currencyFormatter.string(from: balance as NSNumber)
        }
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildViewFromXib()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        buildViewFromXib()
    }
    
    private func buildViewFromXib() {
        let view = Bundle.main.loadNibNamed("GroupView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    
}
