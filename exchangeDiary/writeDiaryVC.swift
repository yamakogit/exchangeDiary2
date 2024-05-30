//
//  writeDiaryVC.swift
//  exchangeDiary
//
//  Created by 山田航輝 on 2024/05/29.
//

import UIKit

class writeDiaryVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet var titleTextField :UITextField!
    @IBOutlet var photoImageView: UIImageView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var mesageTextView: UITextView!
    
    //none用
    @IBOutlet var noneLabel: UILabel!
    @IBOutlet var photoNoneImageView: UIImageView!
    @IBOutlet var photoBGNoneImageView: UIImageView!
    @IBOutlet var photoNoneLabel: UILabel!
    @IBOutlet var cameraNoneImageView: UIImageView!
    @IBOutlet var cameraBGNoneImageView: UIImageView!
    @IBOutlet var cameraNoneLabel: UILabel!
    
    
    var diaryData: FirebaseClient.DiaryData = FirebaseClient.DiaryData(title: "", photoURL: "", message: "", date: "")

    var noneUIKitArray: Array! = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleTextField.delegate = self
        titleTextField.addTarget(self, action: #selector(writeDiaryVC.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        hideNoneUI(isHidden: false)
        
        mesageTextView.delegate = self
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let date = dateFormatter.string(from: Date())
        diaryData.date = date
        
       
       
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func selectPhoto() {
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
        let picker = UIImagePickerController()  //IV
            picker.sourceType = .photoLibrary
            picker.delegate = self
            present(picker, animated: true)
        } else {
            
            print("PhotoLibrary is not available.")
            OtherHosts.alertDef(view: self, title: "エラー", message: "フォトライブラリへのアクセスを許可してください")
        }
    }
    
    
    @IBAction func takePhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            present(picker, animated: true, completion: nil)
        } else {
            
            print("Camera is not available.")
            OtherHosts.alertDef(view: self, title: "エラー", message: "カメラへのアクセスを許可してください")
        }
    }
    
    
    @IBAction func saveDiary() {
        Task {
            var check = noneChecker()
            
            if check {
                //エラーあり→Alert出す
                OtherHosts.alertDef(view: self, title: "未記入箇所があります", message: "全ての情報を入力しているか確認してください")
                
            } else {
                do {  //エラーなし→保存へ
                    try await FirebaseClient.shared.saveMyDiary(diary: diaryData)
                    //保存完了Alert→初期画面へ戻す
                    performSegue(withIdentifier: "succeedDisplay", sender: self)
                } catch {
                    print("Error fetching spot data: \(error)")
                }
            }
        }
    }
    
    
    // キャンセルボタン時
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    //写真撮影終了時
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            photoImageView.image = selectedImage
            
            Task {
                do {
                    let photoURL = try await FirebaseClient().saveDiaryImage(diaryImage: photoImageView.image!)
                    self.diaryData.photoURL = photoURL
                    hideNoneUI(isHidden: true)
                    picker.dismiss(animated: true, completion: nil)
                } catch {
                    print("Error: ")
                }
            }
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() //キーボードを閉じる
        return true
    }
    
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        diaryData.title = textField.text!
        print("title: \(diaryData.title)")
    }
    
    
    //TV
    func textViewDidChange(_ textView: UITextView) {
        if let text = textView.text {
            diaryData.message = text
        }
    }
    
    
    func hideNoneUI(isHidden tf: Bool) {
        var noneUIKitArray = [noneLabel!, photoNoneImageView!, photoBGNoneImageView!, photoNoneLabel!, cameraNoneImageView!, cameraBGNoneImageView!, cameraNoneLabel!]
        for n in 0...noneUIKitArray.count-1 {
            let ui = noneUIKitArray[n]
            ui.isHidden = tf
        }
    }
    
    
    func noneChecker() -> Bool {
        var checkerArray = [diaryData.date,diaryData.message,diaryData.photoURL,diaryData.title]
        var checkBool = false
        
        for (value) in checkerArray {
            if value == "" {
                checkBool = true
            }
        }
        
        return checkBool
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
