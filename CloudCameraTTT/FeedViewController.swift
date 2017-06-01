//
//  FeedViewController.swift
//  CloudCameraTTT
//
//  Created by Timothy Hull on 3/8/17.
//  Copyright © 2017 Sponti. All rights reserved.
//

import UIKit
import Firebase

    var posts = [Post]()

class FeedViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var following = [String]()
    
    @IBOutlet weak var usersButton: UIBarButtonItem!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nav = self.navigationController?.navigationBar
        nav?.barStyle = UIBarStyle.default
        nav?.tintColor = UIColor.white
        nav?.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        // Center tab bar icon
        let tabBarItems = [tabBarItem!] as [UITabBarItem]
        tabBarItems[0].title = nil
        tabBarItems[0].imageInsets = UIEdgeInsetsMake(6,0,-6,0)
        
        showTip()
    }
    
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        if Reachability.isConnectedToNetwork() == true {
            print("Internet connection OK")
            posts.removeAll()
            following.removeAll()
            fetchPosts()
        } else {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Please check your internet connection",
                                                          message: "",
                                                          preferredStyle: .alert)
            
                let cancel = UIAlertAction(title: "Ok", style: .destructive, handler: { (action) -> Void in })
            
                alert.view.tintColor = UIColor(hexString: "#B53361")
                alert.view.backgroundColor = UIColor(hexString: "#98B5E7")
                alert.view.layer.cornerRadius = 25
            
                alert.addAction(cancel)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    
    
    
    // Logout
    @IBAction func logoutPressed(_ sender: Any) {
        try! FIRAuth.auth()!.signOut()
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginVC")
            self.present(vc, animated: true, completion: nil)
    }
    
    
    
    
    // Pop-up tip to tell user to follow people to see their posts - first run of app only
    func showTip() {
        
        let userDefaults = UserDefaults.standard
        let defaultValues = ["firstRun" : true]
        userDefaults.register(defaults: defaultValues)
        
        if userDefaults.bool(forKey: "firstRun") {
            let alertController = UIAlertController(title: "Welcome", message: "Tap Users in the top right to follow some people and see their photos", preferredStyle: UIAlertControllerStyle.actionSheet)
        
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(alert :UIAlertAction!) in
            })
            alertController.addAction(okAction)
        
            present(alertController, animated: true, completion: nil)
            DispatchQueue.main.async {
                userDefaults.set(false, forKey: "firstRun")
            }

        }
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        let navigationController = UINavigationController(rootViewController: controller.presentedViewController)
        let btnDone = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(FeedViewController.dismiss as (FeedViewController) -> () -> ()))
        navigationController.topViewController?.navigationItem.rightBarButtonItem = btnDone
        return navigationController
    }
    
    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }

    
    
    
// MARK: - Fetch from Firebase
    
    func fetchPosts() {
        
        let ref = FIRDatabase.database().reference()
        ref.child("users").queryOrderedByKey().observe(.value, with: { snapshot in
            
            let users = snapshot.value as! [String : AnyObject]
            
            for (_, value) in users {
                
                if let uid = value["uid"] as? String {
                    
                    if uid == FIRAuth.auth()?.currentUser?.uid {
                        
                        if let followingUsers = value["following"] as? [String : String] {
                            
                            for (_, user) in followingUsers {
                                self.following.append(user)
                            }
                        }
                        self.following.append(FIRAuth.auth()!.currentUser!.uid)
                        
                        ref.child("posts").queryOrderedByKey().observeSingleEvent(of: .value, with: { (snap) in
                        
                            for postSnapshot in snap.children.allObjects as! [FIRDataSnapshot] {
                                let value = postSnapshot.value as! [String : AnyObject]

                                if let userID = value["userID"] as? String {
                                    for each in self.following {
                                        if each == userID {
                                            
                                            let posst = Post()
                                            if let poster = value["poster"] as? String, let likes = value["likes"] as? Int, let pathToImage = value["pathToImage"] as? String, let postID = value["postID"] as? String {
                                                
                                                posst.poster = poster
                                                posst.likes = likes
                                                posst.pathToImage = pathToImage
                                                posst.postID = postID
                                                posst.userID = userID
                                                if let people = value["peopleWhoLike"] as? [String : AnyObject] {
                                                    for (_, person) in people {
                                                        posst.peopleWhoLike.append(person as! String)
                                                    }
                                                }
                                                posts.append(posst)
                                            }
                                        }
                                    }
                                    self.collectionView.reloadData()
                                }
                            }
                        })
                        ref.removeAllObservers()
                    }
                }
            }
        })
    }

    
    
    
    
// MARK: - Collection view data sources
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "postCell", for: indexPath) as! PostCell
        
        cell.postImage.loadImageUsingCacheWithUrlString(posts[indexPath.row].pathToImage)
        cell.postID = posts[indexPath.row].postID
        cell.postImage.contentMode = UIViewContentMode.scaleAspectFill

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if Reachability.isConnectedToNetwork() == true {
            print("Internet connection OK")
            let photoDetailController = self.storyboard?.instantiateViewController(withIdentifier: "photoDetail") as! PhotoDetailController
            
            photoDetailController.selectedPost = posts[indexPath.row]
            
            self.navigationController?.pushViewController(photoDetailController, animated: true)

        } else {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Please check your internet connection",
                                              message: "",
                                              preferredStyle: .alert)
                
                let cancel = UIAlertAction(title: "Ok", style: .destructive, handler: { (action) -> Void in })
                
                alert.view.tintColor = UIColor(hexString: "#B53361")
                alert.view.backgroundColor = UIColor(hexString: "#98B5E7")
                alert.view.layer.cornerRadius = 25
                
                alert.addAction(cancel)
                self.present(alert, animated: true, completion: nil)
                return
            }
        }
    }
    
    
    
    
// MARK: - Collection view layout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0,0,0,0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let imgWidth = collectionView.frame.width/3.0
        return CGSize(width: imgWidth, height: imgWidth)
    }
    
    
    
    

    
    
    

}









