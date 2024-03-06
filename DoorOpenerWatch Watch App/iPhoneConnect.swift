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

func gotoToken(from url: String, completion: @escaping (String?) -> Void) {
    guard let url = URL(string: url) else {
        print("Invalid URL")
        completion(nil)
        return
    }

    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        if let error = error {
            print("Error: \(error)")
            completion(nil)
        } else if let data = data {
            let html = String(data: data, encoding: .utf8)
            do {
                let doc: Document = try SwiftSoup.parse(html ?? "")
                let pElements: Elements = try doc.select("p")
                let pText = try pElements.text()
                completion(pText)
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
                Text("Received: \(iphoneconnectmanager.receivedMessage)")
            }
            .navigationBarTitle("DoorOpener")
            .onReceive(iphoneconnectmanager.$receivedMessage) { newValue in
                if newValue != "" {
                    print("Received: \(newValue)")
                    gotoToken(from: newValue) { pText in
                        if let pText = pText {
                            saveUserInfo(from: pText)
                            loggedIn = true
                            print("all ready")
                        }
                    }
                }
            }
        }
    }
    
    func saveUserInfo(from data: String) {
        // 괄호와 따옴표를 제거하고, 쉼표를 기준으로 두 데이터를 나눕니다.
        let trimmedData = data.trimmingCharacters(in: CharacterSet(charactersIn: "(')"))
        let components = trimmedData.components(separatedBy: "', '")
        
        if components.count == 2 {
            userEmail = components[0]
            userName = components[1]
            
            print("email: \(userEmail), name: \(userName)")
        } else {
            print("Unexpected data format")
        }
    }
}


