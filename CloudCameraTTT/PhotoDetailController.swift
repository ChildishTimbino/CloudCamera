//
//  PhotoDetailController.swift
//  CloudCameraTTT
//
//  Created by Timothy Hull on 3/8/17.
//  Copyright © 2017 Sponti. All rights reserved.
//

import UIKit
import Firebase

class PhotoDetailController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    var postID: String!
    
    // Includes the index path
    var selectedPost: Post!
    
    // UI
    @IBOutlet weak var photoDetailImageView: UIImageView!
    @IBOutlet weak var likeHeart: UIButton!
    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var unlikeHeart: UIButton!

    // Comments
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addCommentTextField: UITextField!
    @IBOutlet weak var addCommentButton: UIButton!
    @IBOutlet weak var addCommentView: UIView!
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addCommentTextField.delegate = self
        
        navigationItem.title = "Photo Detail"
        
        self.likeLabel.text = "\(selectedPost.likes!) Likes"
        self.photoDetailImageView.loadImageUsingCacheWithUrlString(selectedPost.pathToImage)
        self.postID = selectedPost.postID
        if let photoAuthor = selectedPost.poster {
                self.authorNameLabel.text = "Photo by \(photoAuthor)"
        }

        for person in self.selectedPost.peopleWhoLike {
            if person == FIRAuth.auth()!.currentUser!.uid {
                self.likeHeart.isHidden = true
                self.unlikeHeart.isHidden = false
                break
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        observePostComments()
    }
    

    
    
// MARK: - Like/Delete/Comment
    @IBAction func likeButtonPressed(_ sender: AnyObject) {
        self.unlikeHeart.isHidden = false
        self.likeHeart.isHidden = true
        self.unlikeHeart.isEnabled = true
        self.likeHeart.isEnabled = false
        
        let ref = FIRDatabase.database().reference()
        let keyToPost = ref.child("posts").childByAutoId().key
        
        ref.child("posts").child(self.postID).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let post = snapshot.value as? [String : AnyObject] {
                let updateLikes: [String: Any] = ["peopleWhoLike/\(keyToPost)" : FIRAuth.auth()!.currentUser!.uid]
                ref.child("posts").child(self.postID).updateChildValues(updateLikes, withCompletionBlock: { (error, reff) in
                    
                    if error == nil {
                        ref.child("posts").child(self.postID).observeSingleEvent(of: .value, with: { (snap) in
                            
                            if let properties = snap.value as? [String: AnyObject] {
                                if let likes = properties["peopleWhoLike"] as? [String : AnyObject] {
                                    let count = likes.count
                                    self.likeLabel.text = "\(count) Likes"
                                    
                                    
                                    // update Firebase
                                    let update = ["likes" : count]
                                    ref.child("posts").child(self.postID).updateChildValues(update)
                                }
                            }
                        })
                    }
                })
            }
        })
        ref.removeAllObservers()
    }
    
    @IBAction func unlikeButtonPressed(_ sender: AnyObject) {
        self.unlikeHeart.isHidden = true
        self.likeHeart.isHidden = false
        self.unlikeHeart.isEnabled = false
        self.likeHeart.isEnabled = true
        
        let ref = FIRDatabase.database().reference()
        ref.child("posts").child(self.postID).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let properties = snapshot.value as? [String : AnyObject] {
                if let peopleWhoLike = properties["peopleWhoLike"] as? [String : AnyObject] {
                    
                    for (id, person) in peopleWhoLike {
                        if person as? String == FIRAuth.auth()!.currentUser!.uid {
                            ref.child("posts").child(self.postID).child("peopleWhoLike").child(id).removeValue(completionBlock: { (error, reff) in
                                
                                if error == nil {
                                    ref.child("posts").child(self.postID).observeSingleEvent(of: .value, with: { (snap) in
                                        
                                        if let prop = snap.value as? [String : AnyObject] {
                                            if let likes = prop["peopleWhoLike"] as? [String : AnyObject] {
                                                let count = likes.count - 1
                                                self.likeLabel.text = "\(count) Likes"
                                                ref.child("posts").child(self.postID).updateChildValues(["likes" : count])
                                                
                                            } else {
                                                self.likeLabel.text = "0 Likes"
                                                ref.child("posts").child(self.postID).updateChildValues(["likes" : 0])
                                            }
                                        }
                                    })
                                }
                            })
                         break
                        }
                    }
                }
            }
        })
        ref.removeAllObservers()
    }
    
    @IBAction func moreButtonPressed(_ sender: AnyObject) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let destroyAction = UIAlertAction(title: "Delete Photo", style: .destructive) { action in
            print(action)
            self.deletePost()
        }
        
        alertController.addAction(destroyAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true)
    }
    
    func deletePost() {
        
        let uid = FIRAuth.auth()!.currentUser!.uid
        let ref = FIRDatabase.database().reference()
        let storage = FIRStorage.storage().reference(forURL: "gs://cloudcamerattt.appspot.com")
        
        // Remove from FB database
        if let postToRemove = selectedPost.postID {
            ref.child("posts").child(postToRemove).removeValue { (error, ref) in
                if error != nil {
                    print("error \(error)")
                }
                let feedController = self.storyboard?.instantiateViewController(withIdentifier: "feedVC") as! FeedViewController
                feedController.navigationItem.setHidesBackButton(true, animated: false)
                self.navigationController?.pushViewController(feedController, animated: true)
            }
            // Remove from FB storage
            let imageRef = storage.child("posts").child(uid).child("\(selectedPost.postID).jpg")
            imageRef.delete { error in
                if let error = error {
                    print(error)
                    return
                } else {
                    return
                }
            }
        }
    }
    

    
    

    
    
    
    
// MARK: - Table view data sources
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CommentCell
        
        let comment = selectedPost.comments[indexPath.row]
        
        cell.commentAuthorLabel?.text = comment.userId
        cell.commentLabel.text = comment.comment

        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedPost.comments.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let comment = selectedPost.comments[indexPath.row]
            selectedPost.comments.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // Remove from Firebase
            FIRDatabase.database().reference().child("postComments").child(self.postID).child(comment.key).removeValue(completionBlock: { (deleteError: Error?, reference:FIRDatabaseReference) in
                
                // Check if there was an error deleting comment
                if let error = deleteError {
                    
                    // There was a problem deleting comment
                    print(error.localizedDescription)
                    
                } else { 
                    
                    // There was no problem deleting comment 
                    print("Comment should be deleted")
                    print("Comment key is \(comment.key)")
                    
                }
            })
        }
    }
    
    
    
    
    
    
// MARK: - Comment stuff
    
    // Show comment text field
    @IBAction func commentButtonPressed(_ sender: AnyObject) {
        self.addCommentView.isHidden = false
    }

    // Check text field, pass comments to addComment
    @IBAction func addCommentButtonPressed(_ sender: Any) {
        
        if !addCommentTextField.text!.isEmpty {
            addComment(comment: addCommentTextField.text!)
        }
        addCommentTextField.resignFirstResponder()
        self.addCommentTextField.text = nil
        self.view.endEditing(true)
        self.addCommentView.isHidden = true
    }
    
    // Upload to Firebase
    func addComment(comment: String) {
        let postsCommentsRef = FIRDatabase.database().reference().child("postComments").child(self.postID)
        var commentData: [String: String] = [:]
        commentData["userId"] = FIRAuth.auth()!.currentUser!.displayName!
        commentData["comment"] = comment
        postsCommentsRef.childByAutoId().setValue(commentData)
        
        let commentObject = Comment()
        commentObject.userId = FIRAuth.auth()!.currentUser!.displayName!
        commentObject.comment = comment
        selectedPost.comments.append(commentObject)
        tableView.reloadData()
    }
    
    // Listens for changes (comment added), appends arrays & updates table view
    func observePostComments() {
        var comments:[Comment] = [Comment]()
        let postsCommentsRef = FIRDatabase.database().reference().child("postComments").child(self.postID)
        
        postsCommentsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let commentsArray = snapshot.children
            
            while let tempComment = commentsArray.nextObject() as? FIRDataSnapshot {
                
                if let commentDictionary = tempComment.value as? [String: AnyObject] {
                    
                    let commentObject = Comment()
                    commentObject.key = tempComment.key
                    commentObject.userId = commentDictionary["userId"] as? String ?? ""
                    commentObject.comment = commentDictionary["comment"] as? String ?? ""
                    
                    comments.append(commentObject)
                } 
            }
            
            self.selectedPost.comments = comments
            self.tableView.reloadData() 
        }) 
    }

    

    
    
    
// MARK: - Keyboard stuff
    
    // Handle return key pressed instead of send button
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if !addCommentTextField.text!.isEmpty {
            addComment(comment: addCommentTextField.text!)
        }
        addCommentTextField.resignFirstResponder()
        self.addCommentTextField.text = nil
        self.view.endEditing(true)
        self.addCommentView.isHidden = true
        return true
    }
    
    // Move view up with keyboard
    func textFieldDidBeginEditing(_ textField: UITextField) {
        animateViewMoving(up: true, moveValue: 220)
    }
    
    // Move view down with keyboard
    func textFieldDidEndEditing(_ textField: UITextField) {
        animateViewMoving(up: false, moveValue: 220)
    }
    
    // View move animation
    func animateViewMoving (up:Bool, moveValue :CGFloat){
        let movementDuration:TimeInterval = 0.2
        let movement:CGFloat = ( up ? -moveValue : moveValue)
        UIView.beginAnimations( "animateView", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration )
        self.view.frame = self.view.frame.offsetBy(dx: 0,  dy: movement)
        UIView.commitAnimations()
    }


    
    
    
    
}
