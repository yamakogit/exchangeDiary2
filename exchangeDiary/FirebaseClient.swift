//
//  FirebaseClient.swift
//  exchangeDiary
//
//  Created by 山田航輝 on 2024/05/27.
//

import UIKit
import Firebase
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

class FirebaseClient {
    
    var userUid: String = ""
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    static let shared = FirebaseClient()
    
    //userUid取得 (Auth)
    func getUserUid() async throws {
        guard let user = Auth.auth().currentUser else {
            print("ログイン状態不明") //uuid取得失敗
            userUid = ""
            return
        }
        userUid = user.uid //uuid取得成功の場合代入
        print("userUid: \(userUid)")
    }
    
    //userData取得 (Firestore)
    func getUserData() async throws -> UserDataSet {
        //uuid取得
        try await getUserUid()
        
        let snapshot = try await db.collection("User").document(userUid).getDocument()
        
        if let userData = try? snapshot.data(as: UserDataSet.self) {
            return userData //取得成功
        } else {
            return UserDataSet(
                id: userUid,
                name: "",
                iconURL: "",
                groupUID: "",
                diary: [[:]]) //取得失敗->uuidのみreturn
        }
    }
    
    
    
    //DataSets
    struct UserDataSet: Codable {
        @DocumentID var id: String?
        var name: String
        var iconURL: String
        var groupUID: String
        var diary: [[String:String]]
    }
    
    struct GroupDataset: Codable {
        @DocumentID var id: String?
        var groupID: String?
        var latestDate: String?
        var latestOpenedUUID: String?
    }
    
    
}
