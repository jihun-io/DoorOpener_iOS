//
//  LoginWithAppleWatch.swift
//  DoorOpener
//
//  Created by 김지훈 on 3/7/24.
//

import Foundation
import SwiftSoup
import WatchConnectivity


class WatchConnectManager: NSObject, ObservableObject, WCSessionDelegate {
    var session: WCSession
    @Published var receivedMessage = ""

    override init() {
        session = WCSession.default
        super.init()
        session.delegate = self
        session.activate()
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        session.activate()
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
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

func loadToken(from url: String, completion: @escaping (String?) -> Void) {
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

