//
//  SignupViewController.swift
//  CloudCameraTTT
//
//  Created by Timothy Hull on 3/7/17.
//  Copyright © 2017 Sponti. All rights reserved.
//

import UIKit
import Firebase



class SignupViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var selectProfileImageView: UIImageView!
    @IBOutlet weak var signupNextButton: UIButton!
    let picker = UIImagePickerController()
    var userStorage: FIRStorageReference!
    var ref: FIRDatabaseReference!
    let loginBackgroundColor = UIColor(hexString: "#B53361")
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = loginBackgroundColor
        
        picker.delegate = self
        
        // Reference to Firebase storage
        let storage = FIRStorage.storage().reference(forURL: "gs://cloudcamerattt.appspot.com")
        
        // Reference to Firebase Database
        ref = FIRDatabase.database().reference()
        
        // Then set userStorage to be Firebase storage, plus create child node for users
        userStorage = storage.child("users")
    }
    
    
    

    @IBAction func selectProfilePictureButton(_ sender: AnyObject) {
        
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        
        present(picker, animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.selectProfileImageView.image = image
            self.selectProfileImageView.isHidden = false
            signupNextButton.isHidden = false
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func signupNextButtonPressed(_ sender: AnyObject) {
        
        // Make sure text field aren't empty
        guard nameField.text != "", emailField.text != "", passwordField.text != "", confirmPasswordField.text != "" else {return}
        
        if passwordField.text == confirmPasswordField.text {
            FIRAuth.auth()?.createUser(withEmail: emailField.text!, password: passwordField.text!, completion: { (user, error) in
                
                if let error = error {
                    print(error.localizedDescription)
                }
                
                if let user = user {
                    // Use name as Firebase display name for readability
                    let changeRequest = FIRAuth.auth()!.currentUser!.profileChangeRequest()
                    changeRequest.displayName = self.nameField.text!
                    changeRequest.commitChanges(completion: nil)
                    
                    // Create child node from userStorage "users". Profile image set to user's unique ID
                    let imageRef = self.userStorage.child("\(user.uid).jpg")
                    let data = UIImageJPEGRepresentation(self.selectProfileImageView.image!, 0.5)
                    
                    // Upload image to Firebase
                    let uploadTask = imageRef.put(data!, metadata: nil, completion: { (metadata, err) in
                        if err != nil {
                            print(err!.localizedDescription)
                        }
                        imageRef.downloadURL(completion: { (url, er) in
                            if er != nil {
                                print(er?.localizedDescription)
                            }
                            
                            if let url = url {
                                // Dictionary of user info we want to save into Firebase
                                let userInfo: [String: Any] = ["uid" : user.uid,
                                                               "full name" : self.nameField.text!,
                                                               "urlToImage" : url.absoluteString] // absoluteString bc Firebase doesn't accept NSURL
                                
                                // Create child node from users --> user uid --> userInfo
                                self.ref.child("users").child(user.uid).setValue(userInfo)

                                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "tabBarController")
                                self.present(vc, animated: true, completion: nil)
                            }
                        })
                    })
                    uploadTask.resume()
                }
            })
        } else {
            print("Passwords don't match")
        }
    }

    
    
    
    
    
    
    
    
    
    
}
