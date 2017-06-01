//
//  PreviewViewController.swift
//  CloudCameraTTT
//
//  Created by Timothy Hull on 3/19/17.
//  Copyright © 2017 Sponti. All rights reserved.
//

import UIKit
import Firebase

class PreviewViewController: UIViewController {
    
    @IBOutlet weak var previewImage: UIImageView!
    var img: UIImage?
    
    @IBOutlet weak var postCircleView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.previewImage.image = img

        postCircleView.layer.borderColor = UIColor(hexString: "#98B5E7").cgColor
    }

    
    
    @IBAction func postPhoto(_ sender: Any) {
        uploadToFirebase()
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
                    self.navigationController?.popViewController(animated: true)
                    self.tabBarController?.selectedIndex = 0
                }
            })
        }
        uploadTask.resume()
    }
    
    
    
    
}
