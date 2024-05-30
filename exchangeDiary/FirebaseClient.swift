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
import Kingfisher

class FirebaseClient {
    
    var userUid: String = ""
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    static let shared = FirebaseClient()
    
    //userUid取得 (Auth)
    func getUserUid() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            print("ログイン状態不明") //uuid取得失敗
            userUid = ""
            return userUid
        }
        userUid = user.uid //uuid取得成功の場合代入
        print("userUid: \(userUid)")
        return userUid
    }
    
    //userData取得 (Firestore)
    func getUserData(uid: String? = nil) async throws -> UserDataSet {
        //uuid取得
        userUid = try await getUserUid()
        let snapshot = try await db.collection("User").document(uid ?? userUid).getDocument()
        
        if let userData = try? snapshot.data(as: UserDataSet.self) {
            return userData //取得成功
        } else {
            return UserDataSet(
                id: userUid,
                name: "",
                iconURL: "",
                groupUID: "", 
                latestDate: "",
                diary: [[:]]) //取得失敗->uuidのみreturn
        }
    }
    
    //groupData取得 (Firestore)
    func getGroupData() async throws -> GroupDataset {
        //uuid取得
        let userData = try await getUserData()
        
        do {
            let snapshot = try await db.collection("Group").document(userData.groupUID).getDocument()
            let groupData = try snapshot.data(as: GroupDataset.self)
            return groupData
        } catch {
            print("Error fetching spot data: \(error)")
            return GroupDataset()
        }
    }
    
    
    //WhereField 該当UIDのArray取得 相手のUID探し(サブ)
    //使わない
    func getMatchingUIDArray(groupUID: String, completion: @escaping ([String]?, Error?) -> Void) {
        var matchingUIDs: [String] = []
        db.collection("User").whereField("groupUID", isEqualTo: groupUID).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("エラー: \(error)")
            } else {
                // 条件に合致するドキュメントが見つかった場合
                if let documents = querySnapshot?.documents {
                    for document in documents {
                        // ドキュメントID（UID）を取得して配列に追加
                        let uid = document.documentID
                        matchingUIDs.append(uid)
                    }
                    // 条件に合致するUIDが配列matchingUIDsに格納されました
                    print("条件に合致するUID: \(matchingUIDs)")
                    completion(matchingUIDs, nil)
                    
                } else {
                    print("条件に合致するドキュメントがありません。")
                    completion(nil, nil)
                }
            }
        }
    }
    
    
    //getPartnerUIDの取得 <- こっちでやる！
    func getPartnerUID() async throws -> String {
        var partnerUID = ""
        
        
        let userData = try await getUserData()
        
        do {
            var userUid = userData.id
            var groupUid = userData.groupUID
            
            FirebaseClient().getMatchingUIDArray(groupUID: groupUid) { (uids, error) in
                if let error = error {
                    print("エラー: \(error)")
                    
                } else if let uids = uids {
                    print("条件に合致するUIDArray: \(uids)")
                    
                    for n in 0...uids.count {
                        let electedUid = uids[n]
                        if electedUid != userUid {
                            partnerUID = electedUid
                            break
                        }
                    }
                    
                    //パートナーなしで自分のUIDを取得
                    if partnerUID == "" {
                        partnerUID = userUid!
                    }
                }
            }
            
        } catch {
            print("Error fetching spot data: \(error)")
           throw error
        }
        
        return partnerUID
    }
    
    
    //getLatestDiary
    func getLatestDiary(userData: UserDataSet) async throws -> DiaryData {
        let diaries = userData.diary
        let matchingDiary = diaries.last ?? [:]
        let matchingDiaryStruct = DiaryData(title: matchingDiary["title"]!, photoURL: matchingDiary["photoURL"]!, message: matchingDiary["message"]!, date: matchingDiary["date"]!)
        return matchingDiaryStruct
    }
    
    //URLよりStorageから写真の取得
    func getSpotImage(url: String, completion: @escaping (UIImage?) -> Void) {
        let imageURL: URL = URL(string:url)!
        KingfisherManager.shared.downloader.downloadImage(with: imageURL) { result in
            switch result {
            case .success(let value):
                completion(value.image)
            case .failure(let error):
                print(error)
                completion(nil)
            }
        }
    }
    
    //diaryの保存
    //userDataへMyDiary/latestDateの保存 (Firestore)
    func saveMyDiary(diary: DiaryData) async throws {
        
        var userData = try await getUserData()
        let oneDiaryData = ["title": diary.title, "photoURL": diary.photoURL, "message": diary.message, "date": diary.date]
        userData.diary.append(oneDiaryData)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let date = dateFormatter.string(from: Date())
        userData.latestDate = date
        
        let docRef = db.collection("User").document(userUid)
        try docRef.setData(from: userData, merge: true) { error in
            if let error = error {
                print("Error updating document: \(error)") //失敗
            } else {
                print("Document successfully updated") //成功
            }
        }
    }
    
    
    //Storageへ写真の保存 & URLのRETURN
    func saveDiaryImage(diaryImage: UIImage) async throws -> String {
        let storageRef = storage.reference()
        let imagesRef = storageRef.child("DiaryImage")
        let imageName = "\(Date().timeIntervalSince1970).jpg"
        let imageRef = imagesRef.child(imageName)
        
        if let imageData = diaryImage.jpegData(compressionQuality: 0.5) {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            try await imageRef.putDataAsync(imageData, metadata: metadata)
            let url: URL = try await imageRef.downloadURL()
            let urlStr: String = url.absoluteString
            return urlStr
        } else {
            return "https://firebasestorage.googleapis.com/v0/b/exchangediary-6acce.appspot.com/o/Host%2FRectangle%2012.png?alt=media&token=e05f31ec-77cf-40db-b527-1f6f36bb1dd9"
        }
    }
    
    
    
    //DataSets
    struct UserDataSet: Codable {
        @DocumentID var id: String?
        var name: String
        var iconURL: String
        var groupUID: String
        var latestDate: String
        var diary: [[String:String]]
    }
    
    struct GroupDataset: Codable {
        @DocumentID var id: String?
        var groupID: String?
        var latestDate: String?
        var latestOpenedUUID: String?
    }
    
    struct DiaryData {
        var title: String
        var photoURL: String
        var message: String
        var date: String
    }
    
    
}
