//
//  FeedViewController.swift
//  instagram
//
//  Created by Adrian Lindell on 5/6/21.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {
    var myRefreshControl = UIRefreshControl()
    let commentBar = MessageInputBar()
    
    var posts = [PFObject]()
    var totalPosts: Int32 = 0
    var showsCommentBar = false
    var selectedPost: PFObject!
    
    override var inputAccessoryView: UIView? {
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return showsCommentBar
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        // create the comment
        let comment = PFObject(className: "Comments")
        comment["text"] = commentBar.inputTextView.text as String
        comment["post"] = selectedPost
        comment["author"] = PFUser.current()
            
        // every post has an array called comments
        selectedPost.add(comment, forKey: "comments")
            
        selectedPost.saveInBackground { (success, error) in
            if success {
                print("Comment saved")
            } else {
                print("Error saving comment: \(String(describing: error))")
            }
        }
        
        // reload table view to display comment
        tableView.reloadData()
        
        // clear and dismiss input bar
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // one for the post itself and each comment and add comment
        let post = posts[section]
        // ?? means if this is nil, set to []
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        return comments.count + 2;
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // each post is a section
        return posts.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //grab PFObject
        let post = posts[indexPath.section]
        //grab comments
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        // post cell
        if indexPath.row == 0 {
            //grab cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell

            
            let user = post["author"] as! PFUser
            
            cell.usernameLabel.text = user.username
            cell.captionLabel.text = post["caption"] as? String
            
            let imageFile = post["image"] as! PFFileObject
            let urlString = imageFile.url!
            let url = URL(string: urlString)!
            
            cell.photoView.af.setImage(withURL: url)
            
            return cell
        } else if indexPath.row <= comments.count {
            //grab cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell

            // zeroth comment at row 1 so subtract 1
            let comment = comments[indexPath.row - 1]
            
            let user = comment["author"] as! PFUser
            
            cell.usernameLabel.text = user.username
            cell.commentLabel.text = comment["text"] as? String
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
            
            return cell
        }
    }
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        myRefreshControl.addTarget(self, action: #selector(loadPosts), for: .valueChanged)
        
        tableView.refreshControl = myRefreshControl
        
        tableView.keyboardDismissMode = .interactive
        
        // NotificationCenter broadcasts all notifications
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        // Do any additional setup after loading the view.
    }
    
    @objc func keyboardWillBeHidden(note: Notification) {
        commentBar.inputTextView.text = nil
        
        // toggle view
        showsCommentBar = false
        becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadPosts()
    }
    
    @objc func loadPosts() {
        let query = PFQuery(className: "Posts")
        //include the pointers to user and comments and comments.author
        query.includeKeys(["author", "comments", "comments.author"])
        query.limit = 5
        query.order(byDescending: "createdAt")
        
        //get query
        query.findObjectsInBackground { (posts, error) in
            if posts != nil {
                //store data
                self.posts.removeAll()
                self.posts = posts!
                //reload table view
                self.tableView.reloadData()
                self.myRefreshControl.endRefreshing()
            }
        }
    }
    
    func totalPostsCount() {
        let query = PFQuery(className:"Posts")
        query.countObjectsInBackground { (count: Int32, error: Error?) in
            if let error = error {
                // The request failed
                print(error.localizedDescription)
            } else {
                self.totalPosts = count;
            }
        }
    }
    
    func loadMorePosts() {
        let query = PFQuery(className: "Posts")
        //include the pointer to user
        query.includeKey("author")
        query.order(byDescending: "createdAt")
        
        //count available posts and don't load more than available
        totalPostsCount()
        let totalCount = Int(self.totalPosts)
        var limit = totalCount - self.posts.count
        if !(limit > 0) {
            return
        }
        if (limit > 5) {
            limit = 5
        }
        query.limit = limit
        
        query.skip = self.posts.count
        
        //get query
        query.findObjectsInBackground { (posts, error) in
            if posts != nil {
                //store data
                self.posts.append(contentsOf: posts!)
                //reload table view
                self.tableView.reloadData()
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == posts.count {
            loadMorePosts()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == comments.count + 1 {
            //show comment bar
            showsCommentBar = true
            
            // first responder is focus
            becomeFirstResponder()
            commentBar.inputTextView.becomeFirstResponder()
            
            selectedPost = post
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func onLogout(_ sender: Any) {
        PFUser.logOut()
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        let login = main.instantiateViewController(identifier: "LoginViewController")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let delegate = windowScene.delegate as? SceneDelegate else { return }
        
        delegate.window?.rootViewController = login
    }
    

}
