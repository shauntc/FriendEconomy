//
//  RegisterViewController.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-19.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit
import Firebase

class RegisterViewController: UIViewController {

    //MARK: Storyboard Outlets
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    
    
    //MARK: ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    //MARK: Storyboard Actions
    
    @IBAction func registerButtonPressed(_ sender: AnyObject) {
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else{
            return
        }
        guard email != "", password != "", name != "" else {
            return
        }
        
        UserManager.shared.newUser(name: name, email: email, password: password) { (success, error) -> (Void) in
            if success != nil {
                self.performSegue(withIdentifier: "showHome", sender: self)
            }else{
                self.presentError(error: error)
            }
            
        }
        
        
        
    }
    
    
    private func presentError(error:Error?){
        //MARK: Present error here
    }
   

}
