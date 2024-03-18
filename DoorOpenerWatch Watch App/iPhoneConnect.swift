//
//  iPhoneConnect.swift
//  DoorOpenerWatch Watch App
//
//  Created by 김지훈 on 3/7/24.
//

import SwiftUI
import WatchConnectivity
import SwiftSoup

class IPhoneConnectManager: NSObject, ObservableObject, WCSessionDelegate {
    var session: WCSession
    @Published var receivedMessage = ""

    override init() {
        session = WCSession.default
        super.init()
        session.delegate = self
        session.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.receivedMessage = message["message"] as? String ?? "Unknown message"
        }
    }

    func sendMessage(_ message: String) {
        if session.isReachable {
            session.sendMessage(["message": message], replyHandler: nil)
        }
    }
}

class LoginStatus: ObservableObject {
    @Published var complete: Bool = false
}

struct LoginResult: Codable {
    var message: String
    var email: String
    var username: String
}

func gotoToken(from url: String, completion: @escaping (String?) -> Void) {
    @AppStorage("openerURL") var openerURL: String = ""
    
    @AppStorage("user_email") var userEmail: String = ""
    @AppStorage("user_name") var userName: String = ""
    
    guard let url = URL(string: url) else {
        print("Invalid URL")
        completion(nil)
        return
    }
    
    // URL의 기본 부분을 저장합니다.
    if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
       let scheme = urlComponents.scheme,
       let host = urlComponents.host {
        let baseURL = "\(scheme)://\(host)"
        openerURL = baseURL
    }

    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        if let error = error {
            print("Error: \(error)")
            completion(nil)
        } else if let data = data {
            do {
                let loginResult = try JSONDecoder().decode(LoginResult.self, from: data)
                
                let result = loginResult.message
                userEmail = loginResult.email
                userName = loginResult.username
                
                completion(result)
            } catch Exception.Error(let type, let message) {
                print("Message: \(message)")
                completion(nil)
            } catch {
                print("error")
                completion(nil)
            }
        }
    }

    task.resume()
}





struct Login: View {
    @StateObject var iphoneconnectmanager = IPhoneConnectManager()
    @StateObject var loginstatus = LoginStatus()
    
    @AppStorage("user_email") var userEmail: String = ""
    @AppStorage("user_name") var userName: String = ""
    @AppStorage("logged_in") var loggedIn: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("iPhone의 DoorOpener 앱에서 먼저 로그인을 진행하십시오.")
                    .multilineTextAlignment(.center)
                    .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
//                Text("Received: \(iphoneconnectmanager.receivedMessage)")
            }
            .navigationBarTitle("DoorOpener")
            .onReceive(iphoneconnectmanager.$receivedMessage) { newValue in
                if newValue != "" {
                    print("Received: \(newValue)")
                    gotoToken(from: newValue) { result in
                        if result != nil {
                            loggedIn = true
                            iphoneconnectmanager.sendMessage("Success!")
                            print("all ready")
                        }
                    }
                }
            }
        }
    }
}


func logout() {
    @AppStorage("user_email") var userEmail: String = ""
    @AppStorage("user_name") var userName: String = ""
    @AppStorage("logged_in") var loggedIn: Bool = false
    
    let url = URL(string: "https://dooropener.jihun.io/logout")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    let session = URLSession(configuration: .default)
    let task = session.dataTask(with: request) { (data, response, error) in
        if let error = error {
            print("Error: \(error)")
            DispatchQueue.main.async {
                loggedIn = false
                UserDefaults.standard.set(false, forKey: "loginSuccessful")
                userEmail = ""
                userName = ""
                print("로그아웃 완료!!!")
            }
        } else {
            DispatchQueue.main.async {
                loggedIn = false
                UserDefaults.standard.set(false, forKey: "loginSuccessful") 
                userEmail = ""
                userName = ""
                print("로그아웃 완료!!!")
            }
        }
    }
    task.resume()
}
