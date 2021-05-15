//
//  FeedViewController.swift
//  instagram
//
//  Created by Adrian Lindell on 5/6/21.
//

import UIKit
import Parse
import AlamofireImage

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var myRefreshControl = UIRefreshControl()
    
    var posts = [PFObject]()
    var totalPosts: Int32 = 0
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //grab cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
        
        //grab PFObject
        let post = posts[indexPath.row]
        
        let user = post["author"] as! PFUser
        
        cell.usernameLabel.text = user.username
        cell.captionLabel.text = post["caption"] as? String
        
        let imageFile = post["image"] as! PFFileObject
        let urlString = imageFile.url!
        let url = URL(string: urlString)!
        
        cell.photoView.af.setImage(withURL: url)
        
        return cell
    }
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        myRefreshControl.addTarget(self, action: #selector(loadPosts), for: .valueChanged)
        
        tableView.refreshControl = myRefreshControl

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadPosts()
    }
    
    @objc func loadPosts() {
        let query = PFQuery(className: "Posts")
        //include the pointer to user
        query.includeKey("author")
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
