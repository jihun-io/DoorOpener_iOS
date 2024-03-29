//
//  DoorOpenerWatchClass.swift
//  DoorOpenerWatch Watch App
//
//  Created by 김지훈 on 3/7/24.
//

import SwiftUI
import Foundation

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
    
    @AppStorage("openerURL") var openerURL: String = ""
    
    func openDoor() {
        var openerLink: String
        if isTest && noNotification {
            openerLink = "\(openerURL)/openwithapp?isNoPush=1"
        } else if isTest && !noNotification {
            openerLink = "\(openerURL)/openwithapp?isTest=1"
        } else {
            openerLink = "\(openerURL)/openwithapp"
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
}


