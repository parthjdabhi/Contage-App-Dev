//
//  PrivateChatViewController.swift
//  PokeTrainerApp
//
//  Created by iParth on 7/30/16.
//  Copyright © 2016 iParth. All rights reserved.
//
import UIKit
import Firebase
import JSQMessagesViewController

class MyChatViewController: JSQMessagesViewController {
    
    // MARK: Properties
    var userIsTypingRef: FIRDatabaseReference!
    var usersTypingQuery: FIRDatabaseQuery!
    
    var groupId:String? = ""
    var OppUserId:String? = ""
    var typingCounter: Int = 0
    var firebase1: FIRDatabaseReference?
    var firebase2: FIRDatabaseReference?
    var loaded: Int = 0
    var loads: [AnyObject] = []
    var loadIds: [AnyObject] = []
    var messages: [AnyObject] = []
    var jsqmessages: [JSQMessage] = [JSQMessage]()
    var avatars: [NSObject : AnyObject] = [:]
    var avatarIds: [AnyObject] = []
    var bubbleImageOutgoing: JSQMessagesBubbleImage?
    var bubbleImageIncoming: JSQMessagesBubbleImage?
    
    var navigationBar = UINavigationBar()
    
    let COLOR_OUTGOING = UIColor.lightGrayColor() //init(red: (204.0/255.0), green: (217.0/255.0), blue: (243.0/255.0), alpha: 0.5)
    let COLOR_INCOMING = UIColor.init(red: (51.0/255.0), green: (51.0/255.0), blue: (94.0/255.0), alpha: 1.0)
    
    var ref:FIRDatabaseReference!
    let MyUserID = FIRAuth.auth()?.currentUser?.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // No avatars
//        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
//        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        
        //self.inputAccessoryView
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        self.showTypingIndicator = false;
        self.showLoadEarlierMessagesHeader = false;
        
        self.collectionView.collectionViewLayout.invalidateLayoutWithContext(JSQMessagesCollectionViewFlowLayoutInvalidationContext.init())
        
        let tap = UITapGestureRecognizer(target: self, action : #selector(self.handleTap(_:)))
        self.collectionView.addGestureRecognizer(tap)

        
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        
        self.title = "Chat"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: #selector(self.ActionGoBack(_:)))
        loads = [AnyObject]()
        loadIds = [AnyObject]()
        messages = [AnyObject]()
        jsqmessages = [JSQMessage]()
        avatars = [NSObject : AnyObject]()
        avatarIds = [AnyObject]()
        
        
        
        // Create the navigation bar
        navigationBar = UINavigationBar(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, 64)) // Offset by 20 pixels vertically to take the status bar into account
        navigationBar.backgroundColor = UIColor.whiteColor()
        navigationBar.barTintColor = AppState.sharedInstance.appBlueColor
        navigationBar.tintColor = .whiteColor()
        navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        
        // Create a navigation item with a title
        let navigationItem = UINavigationItem()
        navigationItem.title = "Chat"
        let leftButton =  UIBarButtonItem(title: "Back", style:   UIBarButtonItemStyle.Plain, target: self, action: #selector(self.ActionGoBack(_:)))
        leftButton.tintColor = UIColor.whiteColor()
        navigationItem.leftBarButtonItem = leftButton
        navigationBar.items = [navigationItem]
        self.view.addSubview(navigationBar)
        
        
        //let bubbleFactoryOutgoing: JSQMessagesBubbleImageFactory = JSQMessagesBubbleImageFactory(bubbleImage: UIImage.jsq_bubbleRegularImage(), capInsets: UIEdgeInsetsZero)
        //let bubbleFactoryIncoming: JSQMessagesBubbleImageFactory = JSQMessagesBubbleImageFactory(bubbleImage: UIImage.jsq_bubbleRegularImage(), capInsets: UIEdgeInsetsZero)
        //bubbleImageOutgoing = bubbleFactoryOutgoing.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
        //bubbleImageIncoming = bubbleFactoryIncoming.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        
        bubbleImageOutgoing = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(AppState.sharedInstance.appBlueColor)
        bubbleImageIncoming = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        
        self.topContentAdditionalInset = 44
        
        self.inputToolbar.contentView.leftBarButtonItem = nil
        self.showLoadEarlierMessagesHeader = false
        
        
        firebase1 = FIRDatabase.database().referenceWithPath(FMESSAGE_PATH).child(groupId!)
        firebase2 = FIRDatabase.database().referenceWithPath(FTYPING_PATH).child(groupId!)
        
        //self.loadMessages()
        self.observeMessages()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func  preferredStatusBarStyle()-> UIStatusBarStyle {
        return UIStatusBarStyle.Default
    }
    
    //Go Back to Previous screen
    @IBAction func ActionGoBack(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func handleTap(sender: UITapGestureRecognizer) {
        print("called swipe")
    }
    
    func insertMessages()
    {
        for message in self.messages {
            let userId = message[FMESSAGE_USERID] as? String ?? ""
            let name = message[FMESSAGE_USER_NAME] as? String ?? ""
            let date = (message[FMESSAGE_CREATEDAT] as! String).asDate
            let text = message[FMESSAGE_TEXT] as? String ?? "";
            
            let jsqMsg = JSQMessage.init(senderId: userId, senderDisplayName: name, date: date, text: text)
            self.jsqmessages.append(jsqMsg)
        }
        
        
        self.finishReceivingMessageAnimated(true)
    }
    
    // MARK: - Message sendig methods
    
    func messageSend(text: String)
    {
        var message: [String:AnyObject] =  Dictionary()
        message[FMESSAGE_GROUPID] = groupId;
        message[FMESSAGE_USERID] = MyUserID;
        message[FMESSAGE_USER_NAME] = senderDisplayName;
        message[FMESSAGE_STATUS] = TEXT_DELIVERED;
        message[FMESSAGE_TEXT] = text;
        message[FMESSAGE_TYPE] = MESSAGE_TEXT;
        message[FMESSAGE_CREATEDAT] = NSDate().customFormatted
        
        //Add Jsq Message
        //let userId = message[FMESSAGE_USERID] as? String ?? ""
        //let name = message[FMESSAGE_USER_NAME] as? String ?? ""
        //let date = (message[FMESSAGE_CREATEDAT] as! String).asDate
        
        //let maskOutgoing = (MyUserID == (message[FMESSAGE_USERID] as? String ?? ""))
        //let jsqMsg = JSQMessage.init(senderId: userId, senderDisplayName: name, date: date, text: text)
        //self.jsqmessages.append(jsqMsg)
        //messages.append(messages)
        
        
        ref.child(FMESSAGE_PATH).child(self.groupId!).childByAutoId().updateChildValues(message) { (error, FIRDBRef) in
            if error == nil {
                print("saved recent object : \(message)")
            } else {
                print("Failed to save recent object : \(message)")
            }
        }
        
        self.collectionView?.reloadData()
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage()
        
    }
    
    
    // Group Chat
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return self.jsqmessages[indexPath.row]
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.jsqmessages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = jsqmessages[indexPath.item]
        if message.senderId == senderId {
            return bubbleImageOutgoing
        } else {
            return bubbleImageIncoming
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        
        if (message["userId"] as? String ?? "") == senderId {
            cell.textView!.textColor = UIColor.whiteColor()
            if let image = AppState.sharedInstance.currentUserImage {
                cell.avatarImageView.image = JSQMessagesAvatarImageFactory.circularAvatarImage(image, withDiameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
            }
        } else {
            cell.textView!.textColor = UIColor.blackColor()
            FIRDatabase.database().reference().child("users").child(message["userId"] as? String ?? "").child("profileData").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                AppState.sharedInstance.currentUser = snapshot
                if let base64String = snapshot.value?["userPhoto"] as? String {
                    cell.avatarImageView.image = JSQMessagesAvatarImageFactory.circularAvatarImage(CommonUtils.sharedUtils.decodeImage(base64String), withDiameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
                } else {
                    if let facebookData = snapshot.value?["facebookData"] as? [String : String] {
                        if let image_url = facebookData["profilePhotoURL"]  {
                            print(image_url)
                            let image_url_string = image_url
                            let url = NSURL(string: "\(image_url_string)")
                            cell.avatarImageView.sd_setImageWithURL(url)
                        }
                    }
                }})
        }
        
        
        
        return cell
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        if indexPath.item % 3 == 0 {
            let jsqmessage: JSQMessage = jsqmessages[indexPath.item]
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(jsqmessage.date)
        }
        else {
            return nil
        }
    }
    
    private func observeMessages()
    {
        let firebase: FIRDatabaseReference = FIRDatabase.database().referenceWithPath(FMESSAGE_PATH).child(groupId!)
        firebase.observeEventType(.ChildAdded, withBlock: {(snapshot: FIRDataSnapshot) -> Void in
            if snapshot.exists() {
                if var dic = snapshot.valueInExportFormat() as? [String:AnyObject] {
                    
                    self.messages.append(dic)
                    
                    let userId = dic[FMESSAGE_USERID] as? String ?? ""
                    let name = dic[FMESSAGE_USER_NAME] as? String ?? ""
                    let date = (dic[FMESSAGE_CREATEDAT] as? String ?? "").asDate
                    let text = dic[FMESSAGE_TEXT] as? String ?? ""
                    
                    let jsqMsg = JSQMessage.init(senderId: userId, senderDisplayName: name, date: date, text: text)
                    self.jsqmessages.append(jsqMsg)
                    
                    self.collectionView?.reloadData()
                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    
                    
                    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
                     //
                     // Here we got all message send by opposite user and we can set its
                     // status to read
                     //
                     // I AM FACING PROBLEM HERE TO UPDATE MESSAGE RECORD STATUS TO READ
                     //
                     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
                    
                    // Check if any unread message sent by Oppposite user
                    
                    if (dic[FRECENT_USERID] as? String ?? "") ==  self.OppUserId
                        && (dic[FMESSAGE_STATUS] as? String ?? "") ==  TEXT_DELIVERED
                    {
                        print("Mark this Convesion As Read Convesation : \(dic)")
                        print(snapshot.key)

                        //Update Status to read
                        dic[FMESSAGE_STATUS] = TEXT_READ

                        let firebaseR: FIRDatabaseReference = FIRDatabase.database().referenceWithPath(FMESSAGE_PATH).child(self.groupId!).child(snapshot.key)
                        firebaseR.updateChildValues(dic) { (error, FIRDBRef) in
                            if error == nil {
                                print("Message marked as read")
                            } else {
                                print("Failed to mark message as read")
                            }
                        }
                    }
                }
            }
        })
    }
    
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
    }
    
    // MARK: - JSQMessagesViewController method overrides
    
    override func didPressSendButton(button: UIButton, withMessageText text: String, senderId: String, senderDisplayName name: String, date: NSDate) {
        self.messageSend(text)
    }
    
}



extension NSDateFormatter {
    convenience init(dateFormat: String) {
        self.init()
        self.dateFormat =  dateFormat
    }
}

extension NSDate {
    struct Formatter {
        static let custom = NSDateFormatter(dateFormat: "dd/M/yyyy, H:mm:ss")
    }
    var customFormatted: String {
        return Formatter.custom.stringFromDate(self)
    }
}

extension String {
    var asDate: NSDate? {
        return NSDate.Formatter.custom.dateFromString(self)
    }
    func asDateFormatted(with dateFormat: String) -> NSDate? {
        return NSDateFormatter(dateFormat: dateFormat).dateFromString(self)
    }
}

extension NSDate {
    
    func getElapsedInterval() -> String {
        
        var interval = NSCalendar.currentCalendar().components(.Year, fromDate: self, toDate: NSDate(), options: []).year
        
        if interval > 0 {
            return interval == 1 ? "\(interval)" + " " + "year ago" :
                "\(interval)" + " " + "years ago"
        }
        
        interval = NSCalendar.currentCalendar().components(.Month, fromDate: self, toDate: NSDate(), options: []).month
        if interval > 0 {
            return interval == 1 ? "\(interval)" + " " + "month ago" :
                "\(interval)" + " " + "months ago"
        }
        
        interval = NSCalendar.currentCalendar().components(.Day, fromDate: self, toDate: NSDate(), options: []).day
        if interval > 0 {
            return interval == 1 ? "\(interval)" + " " + "day ago" :
                "\(interval)" + " " + "days ago"
        }
        
        interval = NSCalendar.currentCalendar().components(.Hour, fromDate: self, toDate: NSDate(), options: []).hour
        if interval > 0 {
            return interval == 1 ? "\(interval)" + " " + "hour ago" :
                "\(interval)" + " " + "hours ago"
        }
        
        interval = NSCalendar.currentCalendar().components(.Minute, fromDate: self, toDate: NSDate(), options: []).minute
        if interval > 0 {
            return interval == 1 ? "\(interval)" + " " + "minute ago" :
                "\(interval)" + " " + "minutes ago"
        }
        
        return "a moment ago"
    }
}
