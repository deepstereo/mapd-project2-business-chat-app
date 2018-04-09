//
//  ChatServices.swift
//  business-chat-app
//
//  Created by Timofei Sopin on 2018-03-31.
//  Copyright © 2018 Brogrammers. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import CryptoSwift


class ChatServices {
  
  var testOlolo = [String]()
  
  static let instance = ChatServices()
  
  private var _REF_DATABASE = DATABASE
  private var _REF_CHATS = DATABASE.child("chats")
  
  var REF_CHATS: DatabaseReference {
    
    _REF_CHATS.keepSynced(true)
    return _REF_CHATS
  }
  
  // Create a new group chat
  func createChat(forChatName: String, forMemberIds memberIds: [String], forGroupChat isGroupChat: Bool, handler: @escaping (_ chatCreated: Bool) -> ()) {
    
    var newMembers = [String:Bool]()
    var md5ChatId = String()
    
    switch isGroupChat{
      
    case true:
      
      for member in memberIds {
        
        newMembers[member] = true
      }
      
      REF_CHATS.childByAutoId().setValue(["isGroupChat" : isGroupChat,
                                          "members" : newMembers,
                                          "chatName" : "chatName"])
      handler(true)
      
    case false:
      
      for memberId in memberIds {
        
        var memberAndCurrentUser: [String] = [memberId, currentUserId!]
        memberAndCurrentUser = memberAndCurrentUser.sorted()
        
        md5ChatId = memberAndCurrentUser.joined().md5()
        
        let chatName = memberId + currentUserId!
        
        REF_CHATS.child(md5ChatId).setValue(["isGroupChat" : isGroupChat,
                                             "members" : [memberId:true, currentUserId! : true],
                                             "chatName" : chatName])
      }
      handler(true)
    }
    //    FirebaseMessagingServices.shared.subscribe(to: .newMessage)
  }
  
  func getMyPersonalChats(handler: @escaping (_ contactsArray: [Chat]) -> ()) {
    
    var chatsArray = [Chat]()
    REF_CHATS.observeSingleEvent(of: .value) { (groupSnapshot) in
      guard let groupSnapshot = groupSnapshot.children.allObjects as? [DataSnapshot] else {return}
      
      for group in groupSnapshot {
        guard let isGroupArray = group.childSnapshot(forPath: "isGroupChat").value as? Bool else {return}
        guard let memberArray = group.childSnapshot(forPath: "members").value as? [String:Bool] else {return}
        if  isGroupArray == false && memberArray.keys.contains(currentUserId!) {
          
          let returnedChatName = group.childSnapshot(forPath: "chatName").value as! String
          let groupKey = group.key
          let chatName = returnedChatName.replacingOccurrences(of: currentUserId!, with: "")
          let group = Chat(name: chatName, members: memberArray, chatKey: groupKey, memberCount: "\(memberArray.count)")
          
          chatsArray.append(group)
        }
      }
      handler(chatsArray)
    }
  }
  
  //    Get my group chats
  func getMyGroups(handler: @escaping (_ groupsArray: [Chat]) -> ()) {
    
    var groupsArray = [Chat]()
    REF_CHATS.observeSingleEvent(of: .value) { (groupSnapshot) in
      guard let groupSnapshot = groupSnapshot.children.allObjects as? [DataSnapshot] else {return}
      
      for group in groupSnapshot {
        guard let isGroupArray = group.childSnapshot(forPath: "isGroupChat").value as? Bool else {return}
        guard let memberArray = group.childSnapshot(forPath: "members").value as? [String:Bool] else {return}
        
        if  isGroupArray == true && memberArray.keys.contains(currentUserId!) {
          
          guard let groupName = group.childSnapshot(forPath: "chatName").value as? String else {return}
          
          let group = Chat(name: groupName, members: memberArray, chatKey: group.key, memberCount: "\(memberArray.count)")
          
          groupsArray.append(group)
        }
      }
      handler(groupsArray)
    }
  }
  
  //Get personal chats ID's by members ID's
  func getMyPersonalChatsIds(withMe myId: String, handler: @escaping (_ uidArray: [String:Bool]) -> ()) {
    
    REF_CHATS.observeSingleEvent(of: .value) { (userSnapshot) in
      
      var chatIdsArray = [String:Bool]()
      guard let userSnapshot = userSnapshot.children.allObjects as? [DataSnapshot] else {return}
      
      for chat in userSnapshot {
        
        guard let chatId = chat.childSnapshot(forPath: "members").value as? [String:Bool] else {return}
        if chatId.keys.contains(currentUserId!) {
          chatIdsArray[chat.key] = true
        }
      }
      handler(chatIdsArray)
    }
  }
  
  //Get group chats ID's by members ID's
  func getMyGroupIds(withMe myId: String, handler: @escaping (_ uidArray: [String:Bool]) -> ()) {
    
    REF_CHATS.observeSingleEvent(of: .value) { (userSnapshot) in
      
      var chatIdsArray = [String:Bool]()
      
      guard let userSnapshot = userSnapshot.children.allObjects as? [DataSnapshot] else {return}
      
      for chat in userSnapshot {
        
        guard let isGroup = chat.childSnapshot(forPath: "isGroupChat").value as? Bool else {return}
        guard let chatId = chat.childSnapshot(forPath: "members").value as? [String:Bool] else {return}
        if chatId.contains(where: { $0.value }) && isGroup == true {
          chatIdsArray[chat.key] = true
        }
      }
      handler(chatIdsArray)
    }
  }
}
