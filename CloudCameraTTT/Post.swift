//
//  Post.swift
//  CloudCameraTTT
//
//  Created by Timothy Hull on 3/8/17.
//  Copyright © 2017 Sponti. All rights reserved.
//

import UIKit

class Post: NSObject {
    
    var poster: String!
    var likes: Int!
    var pathToImage: String!
    var userID: String!
    var postID: String!
    var peopleWhoLike: [String] = [String]()
    
    var comments: [Comment] = []
}
