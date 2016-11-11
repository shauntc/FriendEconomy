//
//  AddBillView.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-20.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit

class AddBillView: UIView, UITableViewDataSource {
    
    //MARK: - Storyboard Outlets
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var midLabel: UILabel!
    @IBOutlet weak var titleTextField: RecieptTextField!
    
    @IBOutlet weak var amountTextField: RecieptTextField!
    //MARK: - Variables
    
    var group: Group?
    
    //MARK: - Initializers
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        buildViewFromXib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildViewFromXib()
        configureView()
    }
    
    //MARK: - View Configuration
    
    func configureView() {
        topLabel.font = UIFont.iron_receiptFont(size: 30)
        midLabel.font = UIFont.iron_receiptFont(size: 20)
        bottomLabel.font = UIFont.iron_receiptFont(size: 15)
        backgroundImage.image = #imageLiteral(resourceName: "paper-texture")

        tableView.separatorColor = UIColor.iron_receiptBlue
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
    }
    
    private func buildViewFromXib() {
        let view = Bundle.main.loadNibNamed("AddBillView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    
    //MARK: - TableView DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let groupMembers = group?.members {
            return groupMembers.count
        }else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.backgroundColor = .clear
        
        if let member = group?.members?[indexPath.row] {
            cell.textLabel?.text = member.name
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = .darkText
            cell.textLabel?.font = UIFont.iron_receiptFont(size: 30)
            cell.selectionStyle = .blue
        }
        
        return cell
    }

}
