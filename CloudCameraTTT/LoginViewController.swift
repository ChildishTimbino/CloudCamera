//
//  LoginViewController.swift
//  CloudCameraTTT
//
//  Created by Timothy Hull on 3/7/17.
//  Copyright © 2017 Sponti. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    let loginBackgroundColor = UIColor(hexString: "#B53361")
    


    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = loginBackgroundColor
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // Go straight to feed if user has already signed in
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let user = user {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "tabBarController")
                self.present(vc, animated: true, completion: nil)
            } else {
                return
            }
        }
    }
 
    @IBAction func loginPressed(_ sender: AnyObject) {
        
        guard emailField.text != "", passwordField.text != "" else {return}
        
        FIRAuth.auth()?.signIn(withEmail: emailField.text!, password: passwordField.text!, completion: { (user, error) in
            
            if let error = error {
                print(error.localizedDescription)
                
                // Incorrect login credentials alert
                let alert = UIAlertController(title: "Incorrect email or password",
                                              message: "Please enter a valid email and password",
                                              preferredStyle: .alert)
                
                let cancel = UIAlertAction(title: "Ok", style: .destructive, handler: { (action) -> Void in })
                
                alert.view.tintColor = UIColor(hexString: "#B53361")
                alert.view.backgroundColor = UIColor(hexString: "#98B5E7")
                alert.view.layer.cornerRadius = 25
                
                alert.addAction(cancel)
                self.present(alert, animated: true, completion: nil)
            }
                if let user = user {
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "tabBarController")
                    self.present(vc, animated: true, completion: nil)
                }
        })
    }
    
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    

}
