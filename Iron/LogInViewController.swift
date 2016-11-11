//
//  LogInViewController.swift
//  Iron
//
//  Created by Shaun Campbell on 2016-10-18.
//  Copyright © 2016 Shaun Campbell. All rights reserved.
//

import UIKit
import Firebase

class LogInViewController: UIViewController {

    //MARK: Storyboard Outlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    //MARK: Storyboard Actions
    
    @IBAction func logInButtonPressed(_ sender: UIButton) {
        
        guard let password = passwordTextField.text, let email = emailTextField.text, passwordTextField.text != "", emailTextField.text != "" else {
            presentAlert(title: "Empty Field", message: "Please fill in an email and password")
            return;
        }
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            //Handle log in
        })
    }
    @IBAction func registerButtonPressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showRegistration", sender: self)
    }
    
    func presentAlert(title:String, message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        navigationController?.show(alert, sender: self)
    }
    
    
}
