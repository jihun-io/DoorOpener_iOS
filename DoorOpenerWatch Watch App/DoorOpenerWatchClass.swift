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
}


