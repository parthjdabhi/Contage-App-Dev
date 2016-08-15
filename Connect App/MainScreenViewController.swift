//
//  MainScreenViewController.swift
//  Connect App
//
//  Created by Dustin Allen on 6/22/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import SDWebImage

class MainScreenViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var friendRequests: UILabel!
    @IBOutlet var image1: UIImageView!
    var ref:FIRDatabaseReference!
    var user: FIRUser!
    
    override func viewDidLoad() {
        
        //try! FIRAuth.auth()?.signOut()
        
        ref = FIRDatabase.database().reference()
        user = FIRAuth.auth()?.currentUser
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        ref.child("users").child(userID!).observeEventType(.Value, withBlock: { (snapshot) in
            AppState.sharedInstance.currentUser = snapshot
            if let base64String = snapshot.value!["image"] as? String {
                // decode image
                self.image1.image = CommonUtils.sharedUtils.decodeImage(base64String)
            } else {
                if let facebookData = snapshot.value!["facebookData"] as? [String : String] {
                    if let image_url = facebookData["profilePhotoURL"]  {
                        print(image_url)
                        let image_url_string = image_url
                        let url = NSURL(string: "\(image_url_string)")
                        self.image1.sd_setImageWithURL(url)
                    }
                } else if let twitterData = snapshot.value!["twitterData"] as? [String : String] {
                    if let image_url = twitterData["profile_image_url"]  {
                        print(image_url)
                        let image_url_string = image_url
                        let url = NSURL(string: "\(image_url_string)")
                        self.image1.sd_setImageWithURL(url)
                    }
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
        image1.layer.borderWidth = 2
        image1.layer.borderColor = UIColor.whiteColor().CGColor
        
        self.friendRequests.hidden = true
        
        //Mark check inbox
        checkInbox()
    }
    
    /*
     @IBAction func openCameraButton(sender: AnyObject) {
     
     if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
     let imagePicker = UIImagePickerController()
     imagePicker.delegate = self
     imagePicker.sourceType = UIImagePickerControllerSourceType.Camera;
     imagePicker.allowsEditing = false
     self.presentViewController(imagePicker, animated: true, completion: nil)
     }
     }
     
     @IBAction func openPhotoLibraryButton(sender: AnyObject) {
     
     if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
     let imagePicker = UIImagePickerController()
     imagePicker.delegate = self
     imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary;
     imagePicker.allowsEditing = true
     self.presentViewController(imagePicker, animated: true, completion: nil)
     }
     
     }
     
     @IBAction func saveButton(sender: AnyObject) {
     
     let imageData = UIImageJPEGRepresentation(image1.image!, 0.6)
     let compressedJPGImage = UIImage(data: imageData!)
     UIImageWriteToSavedPhotosAlbum(compressedJPGImage!, nil, nil, nil)
     
     let alert = UIAlertView(title: "Wow", message: "This is your new Snagged photo!", delegate: nil, cancelButtonTitle: "Ok")
     alert.show()
     
     }*/
    
    override func  preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        image1.image = image
        //self.dismissViewControllerAnimated(true, completion: nil);
        self.navigationController?.popViewControllerAnimated(true)  //Changed to Push
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    
    @IBAction func selectPotalView(sender: AnyObject) {        
        
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("PortalViewController") as! PortalViewController!
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func selectContactsSocialView(sender: AnyObject) {
        
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("ContactSocialViewController") as! ContactSocialViewController!
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    @IBAction func btnRecentChat(sender: AnyObject) {
        
        let recentChatViewController = self.storyboard?.instantiateViewControllerWithIdentifier("RecentChatViewController") as! RecentChatViewController!
        self.navigationController?.pushViewController(recentChatViewController, animated: true)
        
    }
    
    func checkInbox() -> Void {
        let userId = FIRAuth.auth()?.currentUser?.uid
        let ref = self.ref.child("users").child(userId!).child("friendRequests")
        
        ref.observeEventType(.Value, withBlock: { snapshot in
            let count = snapshot.children.allObjects.count
            self.friendRequests.text = String(count)
            
            if count > 0 {
                self.friendRequests.hidden = false
            } else {
                self.friendRequests.hidden = true
            }
            }, withCancelBlock: { error in
                print(error.description)
        })
        
        
    }
}