//
//  SignupViewController.swift
//  exchangeDiary
//
//  Created by 山田航輝 on 2024/05/29.
//

import UIKit

import UIKit
import Firebase
import FirebaseAuth

class signupViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var mailTF: UITextField!
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var passTF: UITextField!
    
    var mailAdress: String = ""
    var userName: String = ""
    var password: String = ""
    
    var date = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        let tfArray = [mailTF,nameTF,passTF]
        for tf in 0...2 {
            let electedTf = tfArray[tf]
            electedTf?.delegate = self
            electedTf?.tag = tf
            electedTf?.addTarget(self, action: #selector(signupViewController.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
            //UIControl.Event.editingChangedの時#selector呼び出し
        }
        
        passTF.isSecureTextEntry = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        date = dateFormatter.string(from: Date())
        
        //Placeholder設定(文字と色)
        setTFAttributed(mailTF, kind: "MailAdress")
        setTFAttributed(nameTF, kind: "UserName")
        setTFAttributed(passTF, kind: "Password")
        
        UserDefaults.standard.set(19, forKey: "tripHour") //TripHourの初期設定
        UserDefaults.standard.set("OK", forKey: "tripHourChecker") //旧バージョン対応
        
        // Do any additional setup after loading the view.
    }
    
    
    func setTFAttributed(_ tf: UITextField, kind: String) {
        tf.attributedPlaceholder = NSAttributedString(string: "Enter \(kind)...",
                                                      attributes: [NSAttributedString.Key.foregroundColor: Asset.colorGray.color])
    }
    
    
    //TF
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() //キーボードを閉じる
        return true
    }
    
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        if textField.tag == 0 {
            mailAdress = textField.text!
            print("mailAdress: \(mailAdress)")
            
        } else if textField.tag == 1 {
            userName = textField.text!
            print("userName: \(userName)")
            
        } else if textField.tag == 2 {
            password = textField.text!
            print("password: \(password)")
        }
    }
    
    
    @IBAction func login() {
        
        //入力項目の確認...
        var confirmBool = true
        let confirmDict = ["メールアドレス":mailAdress,"ユーザー名":userName,"パスワード":password]
        for (key, value) in confirmDict {
            if value == "" {
                confirmBool = false
                AlertHost.alertDef(view: self ,title: "\(key)が\n正しく入力されていません", message: "\(key)を\nもう一度入れ直してください。")
                print("error: \(key) is not found.")
            }
        }
        
        if password.count < 7 {
            confirmBool = false
            AlertHost.alertDef(view: self,title: "弱いパスワードです", message: "このパスワードは文字数が少なすぎます。\n最低7文字以上入力してください。")
            print("error: password is weak.")
        }
        
        if confirmBool {
            OtherHosts.activityIndicatorView(view: self.view).startAnimating()
            Auth.auth().createUser (withEmail: mailAdress, password: password) {
                authResult, error in
                print("succeed: signup_createUser")
                if let user = authResult?.user { // authResult?.userでuid取得
                    OtherHosts.activityIndicatorView(view: self.view).stopAnimating()
                    
                    Task {
                        do {
                            try await FirebaseClient.shared.saveUserDatas(currentCoordinateDict: ["lat": "35.675079", "lng": "139.759599"], name: self.userName)
                            dump(user)
                            //MARK: 遷移
                            let tutorialPageVC = TutorialPageViewController()
                            tutorialPageVC.comeFrom = "signup"
                            self.navigationController?.pushViewController(tutorialPageVC, animated: true)
                            
                        } catch {
                            print("Error fetching spot data5/6: \(error)")
                        }
                    }
                    
                    
                } else {
                    dump(error)
                    print("エラー")
                    OtherHosts.activityIndicatorView(view: self.view).stopAnimating()  //AIV
                    AlertHost.alertDef(view: self,title: "エラー", message: "以下のいずれかに該当します\n・パスワードが明らかに脆弱\n・無効なメールアドレスをしようしている\n・メールアドレスがすでに使われている\nもう一度ご確認の上、ご登録ください。")
                    print("error: unknown error happend.")
                    //
                }
                
            }
        }
        
    }

}
