//
//  DoorOpenerClass.swift
//  DoorOpener
//
//  Created by 김지훈 on 3/7/24.
//
import SwiftUI
import UIKit
import Foundation

class SyncWithAppleWatch: ObservableObject {
    @Published var complete: Bool = false
}

class ViewModel: ObservableObject {
    @Published var showOpenView = false
}

class Setup: ObservableObject {
    //    @Published var isTest: Bool = false
} //혹시 모르니 남겨두자...

class Destination: ObservableObject {
    @Published var destinationLink: String = ""
}

class Taptic: ObservableObject {
    @Published var isTap = false
}

struct OpenResult: Codable {
    let result: String
}

class Global: ObservableObject {
    @Published var doorStatus: String = ""
    
    @AppStorage("isTest") var isTest: Bool = false
    @AppStorage("noNotification") var noNotification: Bool = false

    @AppStorage("isAdmin") var isAdmin: Bool = false
    @AppStorage("openerURL") var openerURL: String = ""
    
    func openDoor() {
        var openerLink: String
        if isTest && noNotification {
            openerLink = "\(openerURL)/openwithappjsonwithoutnotification"
        } else if isTest && !noNotification {
            openerLink = "\(openerURL)/openwithapptestjson"
        } else {
            openerLink = "\(openerURL)/openwithappjson"
        }
        
        print(openerLink)

        self.doorStatus = "Pending"
        DispatchQueue.main.async {
            guard let url = URL(string: openerLink) else {
                print("Invalid URL")
                return
            }
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                } else if let data = data {
                    do {
                        let openResult = try JSONDecoder().decode(OpenResult.self, from: data)
                        let doorOpenMessage = openResult.result
                        
                        let now = Date()
                        let formatter = DateFormatter()
                        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        let kstTime = formatter.string(from: now)
                        
                        DispatchQueue.main.async {
                            self.doorStatus = doorOpenMessage
                            print("\(kstTime) 문 상태 업데이트 완료: \(self.doorStatus)")
                        }
                    } catch {
                        print("error")
                    }
                }
            }.resume()
        }
    }
    
    func userInfoLoad() {
        guard let url = URL(string: "\(openerURL)/settings/user/info") else {
            print("Invalid URL")
            return
        }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
            } else if let data = data {
                do {
                    let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(loginResponse.username, forKey: "user_name")
                        UserDefaults.standard.set(loginResponse.email, forKey: "user_email")
                        if loginResponse.isAdmin == 1 {
                            self.isAdmin = true
                        } else {
                            self.isAdmin = false
                        }
                        print("사용자 정보 업데이트 완료: \(UserDefaults.standard.string(forKey: "user_name") ?? ""), \(UserDefaults.standard.string(forKey: "user_email") ?? "")")
                    }
                } catch {
                    print("Error: \(error)")
                }
            }
        }.resume()
    }

}

class UserData: ObservableObject {
    @Published var username: String = UserDefaults.standard.string(forKey: "user_name") ?? ""
    @Published var email: String = UserDefaults.standard.string(forKey: "user_email") ?? ""
}

func sendDeviceTokenToServer(email: String, token: String) {
    @AppStorage("openerURL") var openerURL: String = ""

    // Create the URL and request
    let url = URL(string: "\(openerURL)/apnstokenget")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // Set the request body
    let body = "email=\(email)&token=\(token)"
    request.httpBody = body.data(using: .utf8)
    
    // Create the task
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let error = error {
            print("Error: \(error)")
        } else if let data = data {
            let str = String(data: data, encoding: .utf8)
            print("Received data:\n\(str ?? "")")
        }
    }
    
    // Start the task
    task.resume()
}

func removeDeviceTokenToServer(token: String) {
    @AppStorage("openerURL") var openerURL: String = ""

    // Create the URL and request
    let url = URL(string: "\(openerURL)/apnstokenremove")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // Set the request body
    let body = "token=\(token)"
    request.httpBody = body.data(using: .utf8)
    
    // Create the task
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let error = error {
            print("Error: \(error)")
        } else if let data = data {
            let str = String(data: data, encoding: .utf8)
            print("Received data:\n\(str ?? "")")
        }
    }
    
    // Start the task
    task.resume()
}


class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("토큰 가져오자")
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        // Check if the user is logged in
        if UserDefaults.standard.bool(forKey: "loginSuccessful") {
            // TODO: Send this token to your server...
            var email = UserData().email
            sendDeviceTokenToServer(email: email, token: token)
        } else {
            removeDeviceTokenToServer(token: token)
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}
