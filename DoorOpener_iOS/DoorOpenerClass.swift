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

class Global: ObservableObject {
    @Published var doorStatus: String = ""
    
    @AppStorage("isTest") var isTest: Bool = false
    
    func openDoor() {
        var openerLink: String
        if isTest {
            openerLink = "https://dooropener.jihun.io/openwithapptest"
        } else {
            openerLink = "https://dooropener.jihun.io/openwithapp"
        }
        
        
        self.doorStatus = "문을 여는 중입니다..."
        DispatchQueue.main.async {
            guard let url = URL(string: openerLink) else {
                print("Invalid URL")
                return
            }
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                } else if let data = data,
                          let str = String(data: data, encoding: .utf8),
                          let doorOpenRegex = try? NSRegularExpression(pattern: "<p>(문을 열었습니다.)</p>", options: []),
                          let doorOpenMatch = doorOpenRegex.firstMatch(in: str, options: [], range: NSRange(location: 0, length: str.utf16.count)),
                          let doorOpenRange = Range(doorOpenMatch.range(at: 1), in: str) {
                    let doorOpenMessage = String(str[doorOpenRange])
                    
                    let now = Date()
                    let formatter = DateFormatter()
                    formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let kstTime = formatter.string(from: now)
                    
                    
                    DispatchQueue.main.async {
                        self.doorStatus = doorOpenMessage
                        print("\(kstTime) 문 상태 업데이트 완료: \(self.doorStatus)")
                    }
                }
            }.resume()
        }
    }
    
    func userInfoLoad() {
        guard let url = URL(string: "https://dooropener.jihun.io/settings/user") else {
            print("Invalid URL")
            return
        }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
            } else if let data = data,
                      let str = String(data: data, encoding: .utf8),
                      let nameRegex = try? NSRegularExpression(pattern: "<h1 id=\"name\">(.*)</h1>", options: []),
                      let emailRegex = try? NSRegularExpression(pattern: "<h2 id=\"email\">(.*)</h2>", options: []),
                      let nameMatch = nameRegex.firstMatch(in: str, options: [], range: NSRange(location: 0, length: str.utf16.count)),
                      let emailMatch = emailRegex.firstMatch(in: str, options: [], range: NSRange(location: 0, length: str.utf16.count)),
                      let nameRange = Range(nameMatch.range(at: 1), in: str),
                      let emailRange = Range(emailMatch.range(at: 1), in: str) {
                let name = String(str[nameRange])
                let email = String(str[emailRange])
                
                DispatchQueue.main.async {
                    UserDefaults.standard.set(name, forKey: "user_name")
                    UserDefaults.standard.set(email, forKey: "user_email")
                    print("사용자 정보 업데이트 완료: \(UserDefaults.standard.string(forKey: "user_name") ?? ""), \(UserDefaults.standard.string(forKey: "user_email") ?? "")")
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
    // Create the URL and request
    let url = URL(string: "https://dooropener.jihun.io/apnstokenget")!
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


class NotificationDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("토큰 가져오자")
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        // Check if the user is logged in
        if UserDefaults.standard.bool(forKey: "loginSuccessful") {
            // TODO: Send this token to your server...
            var email = UserData().email
            sendDeviceTokenToServer(email: email, token: token)
        }
    }
}
