//
//  SceneDelegate.swift
//  exchangeDiary
//
//  Created by 山田航輝 on 2024/05/24.
//

import UIKit
import Firebase
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var authListener: Any!


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        autoLogin()
        
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    
    func autoLogin() {
        authListener = Auth.auth().addStateDidChangeListener({ auth, user in
            //その後呼ばれないようにデタッチする
            Auth.auth().removeStateDidChangeListener(self.authListener! as! NSObjectProtocol)
            if user != nil {
                DispatchQueue.main.async {
                    print("loginされています")
                    //ログインされているのでメインのViewへ
                    Task {
                        do { //これに対するもの try await FirebaseClient.shared.getUserData()
                            
                            let userData = try await FirebaseClient.shared.getUserData()
                            let userCoordinateDict = userData.latestOpenedDate
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy.MM.dd"
                            let date = dateFormatter.string(from: Date())
                            
                            if date == userCoordinateDict {
                                //trip済
                                self.goHome()
                                
                            } else {
                                //今日初めて開いた
                                let calendar = Calendar.current
                                let now = Date()
                                let components = calendar.dateComponents([.hour], from: now)
                                let tripHour = UserDefaults.standard.integer(forKey: "tripHour")
                                
                                if let hour = components.hour, hour >= tripHour {
                                    //指定した時間以降
                                } else {
                                    //指定した時間より前
                                    self.goHome()
                                }
                            }
                            
                        } catch {
                            print("Error fetching spot data: \(error)")
                            //getUserData() - エラー
                            self.goHome()
                        }
                    }
                }
                
            } else {
                //認証されていなければ初期画面表示
                //ログインされていない
                print("loginされていません")
                self.goRegister()
            }
        })
    }


}

