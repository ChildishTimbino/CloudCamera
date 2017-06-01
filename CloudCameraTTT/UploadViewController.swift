//
//  UploadViewController.swift
//  CloudCameraTTT
//
//  Created by Timothy Hull on 3/8/17.
//  Copyright © 2017 Sponti. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import Alamofire

class UploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    // Nav bar/picker
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var topOfNavBarView: UIView!
    var picker = UIImagePickerController()

    // Library Upload
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var uploadPhotoLabel: UILabel!

    // Camera
    @IBOutlet weak var takePhotoLabel: UILabel!
    @IBOutlet weak var takePhotoButton: UIButton!
    
    // Preview Image
    @IBOutlet weak var previewImage: UIImageView!
    
    // Post/Upload
    @IBOutlet weak var postCircleView: UIView!
    @IBOutlet weak var postButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        picker.delegate = self
        
        // Navigation Bar
        let nav = self.navigationController?.navigationBar
        nav?.barStyle = UIBarStyle.default
        nav?.tintColor = UIColor.white
        nav?.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]

        // Picker view nav bar
        picker.navigationBar.isTranslucent = false
        let navBarColor = UIColor(hexString: "#707191")
        
        picker.navigationBar.barTintColor = navBarColor
        picker.navigationBar.tintColor = .white
        picker.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.white
        ]
        
        
        self.view.addSubview(topView)
        self.view.addSubview(bottomView)
        setupTopView()
        setupBottomView()
        
        topView.addSubview(takePhotoLabel)
        topView.addSubview(takePhotoButton)

        bottomView.addSubview(uploadPhotoLabel)
        bottomView.addSubview(selectButton)
        
        // Center tab bar icon
        let tabBarItems = [tabBarItem!] as [UITabBarItem]
        tabBarItems[0].title = nil
        tabBarItems[0].imageInsets = UIEdgeInsetsMake(6,0,-6,0)
        
        
        // Check if device has camera, if not go straight to picker
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            return
        } else {
            picker.allowsEditing = true
            picker.sourceType = .photoLibrary
            
            self.present(picker, animated: true, completion: nil)
        }
    }

    
    
    
// Background views
     var topView: UIView = {
        let tv = UIView()
        tv.backgroundColor = UIColor(hexString: "#F99A00")
        tv.translatesAutoresizingMaskIntoConstraints = false
        
        return tv
    }()
    
    var bottomView: UIView = {
        let bv = UIView()
        bv.backgroundColor = UIColor(hexString: "#F9CF00")
        bv.translatesAutoresizingMaskIntoConstraints = false

        return bv
    }()
    
    func setupTopView() {
        topView.widthAnchor.constraint(equalToConstant: self.view.bounds.width).isActive = true
        topView.heightAnchor.constraint(equalToConstant: self.view.bounds.height / 2).isActive = true
        topView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
    }
    
    func setupBottomView() {
        bottomView.widthAnchor.constraint(equalToConstant: self.view.bounds.width).isActive = true
        bottomView.heightAnchor.constraint(equalToConstant: self.view.bounds.height / 2).isActive = true
        bottomView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }
    
    
    
    
    
    
    
    
// Upload to Firebase
    func uploadToFirebase() {
        AppDelegate.instance().showActivityIndicator()
        
        let uid = FIRAuth.auth()!.currentUser!.uid
        let ref = FIRDatabase.database().reference()
        let storage = FIRStorage.storage().reference(forURL: "gs://cloudcamerattt.appspot.com")
        let key = ref.child("posts").childByAutoId().key
        let imageRef = storage.child("posts").child(uid).child("\(key).jpg")
        let data = UIImageJPEGRepresentation(self.previewImage.image!, 0.6)
        
        let uploadTask = imageRef.put(data!, metadata: nil) { (metadata, error) in
            if error != nil {
                print(error!.localizedDescription)
                AppDelegate.instance().dismissActivityIndicator()
                return
            }

            imageRef.downloadURL(completion: { (url, error) in
                
                if let url = url {
                    let feed = ["userID" : uid,
                                "pathToImage" : url.absoluteString,
                                "likes" : 0,
                                "poster" : FIRAuth.auth()!.currentUser!.displayName!,
                                "postID" : key] as [String : Any]
                    
                    let postFeed = ["\(key)" : feed]
                    ref.child("posts").updateChildValues(postFeed)
                    AppDelegate.instance().dismissActivityIndicator()
                    
                    let feedController = self.storyboard?.instantiateViewController(withIdentifier: "feedVC") as! FeedViewController
                    feedController.navigationItem.setHidesBackButton(true, animated: false)
                    
                    self.tabBarController?.selectedIndex = 0
                }
            })
        }
        uploadTask.resume()
    }
    
    
    
    
    
    
// Take photo
    @IBAction func takePhotoButtonTapped(_ sender: AnyObject) {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            picker.mediaTypes = [kUTTypeImage as String]
            picker.allowsEditing = true
            picker.sourceType =  .camera
            picker.title = "Photo Library"
        
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    
    
    
    
    
    
// Choose from Photo Library
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            let previewController = self.storyboard?.instantiateViewController(withIdentifier: "previewVC") as! PreviewViewController
            previewController.img = image
            previewController.navigationItem.setHidesBackButton(true, animated: false)
            self.navigationController?.pushViewController(previewController, animated: true)
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            self.dismiss(animated: true, completion: nil)
            self.tabBarController?.selectedIndex = 0
        } else {
            let feedController = self.storyboard?.instantiateViewController(withIdentifier: "feedVC") as! FeedViewController
            feedController.navigationItem.setHidesBackButton(true, animated: false)
            self.dismiss(animated: true, completion: nil)
            self.tabBarController?.selectedIndex = 0
        }
    }

    @IBAction func selectImagePressed(_ sender: AnyObject) {
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        
        self.present(picker, animated: true, completion: nil)
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        viewController.navigationItem.title = "Photo Library"
    }
    
    @IBAction func postButtonPressed(_ sender: Any) {
        uploadToFirebase()
    }
    
    
    
    

}
