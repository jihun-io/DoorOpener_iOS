//
//  LoginView.swift
//  DoorOpener
//
//  Created by 김지훈 on 3/7/24.
//
import SwiftUI
import Foundation

struct Login: View {
    @Binding var loginSuccessful: Bool
    @EnvironmentObject var userData: UserData
    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false  // 알림 표시 여부를 결정하는 새로운 @State 변수
    
    var body: some View {
        
        VStack {
            if loginSuccessful {
                ParentView()
            } else {
                Text("DoorOpener")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .padding(/*@START_MENU_TOKEN@*/.all, 30.0/*@END_MENU_TOKEN@*/)
                
                Group {
                    TextField("이메일", text: $email)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.secondarySystemBackground)))
                    
                    SecureField("비밀번호", text: $password)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.secondarySystemBackground)))
                }
                
                Button(action: {
                    // 로그인 요청을 보냅니다.
                    let loginInfo = "email=\(self.email)&password=\(self.password)"
                    let loginData = loginInfo.data(using: .utf8)
                    let url = URL(string: "https://dooropener.jihun.io/login")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.httpBody = loginData
                    request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                    let config = URLSessionConfiguration.default
                    config.httpCookieStorage = HTTPCookieStorage.shared
                    let session = URLSession(configuration: config)
                    let task = session.dataTask(with: request) { (data, response, error) in
                        if let error = error {
                            print("Error: \(error)")
                        } else if let httpResponse = response as? HTTPURLResponse {
                            print("Received headers:\n\(httpResponse.allHeaderFields)")
                        }
                        if let data = data {
                            let str = String(data: data, encoding: .utf8)
                            //                            print("Received data 1:\n\(str ?? "")")
                            // 서버의 응답에서 로그인 성공 메시지를 찾습니다.
                            if str?.contains("<h1 class=\"status_message\">로그인을<br>완료했습니다.</h1>") == true {
                                // 사용자 정보 페이지를 요청합니다.
                                let url = URL(string: "https://dooropener.jihun.io/settings/user")!
                                let task = session.dataTask(with: url) { (data, response, error) in
                                    if let error = error {
                                        print("Error: \(error)")
                                    } else if let data = data {
                                        let str = String(data: data, encoding: .utf8)
                                        // 응답에서 사용자 이름과 이메일을 파싱합니다.
                                        if let nameRegex = try? NSRegularExpression(pattern: "<h1 id=\"name\">(.*)</h1>", options: []),
                                           let emailRegex = try? NSRegularExpression(pattern: "<h2 id=\"email\">(.*)</h2>", options: []),
                                           let str = str {
                                            if let nameMatch = nameRegex.firstMatch(in: str, options: [], range: NSRange(location: 0, length: str.utf16.count)),
                                               let emailMatch = emailRegex.firstMatch(in: str, options: [], range: NSRange(location: 0, length: str.utf16.count)),
                                               let nameRange = Range(nameMatch.range(at: 1), in: str),
                                               let emailRange = Range(emailMatch.range(at: 1), in: str) {
                                                let name = String(str[nameRange])
                                                let email = String(str[emailRange])
                                                
                                                DispatchQueue.main.async {
                                                    // 사용자 이름과 이메일을 저장합니다.
                                                    UserDefaults.standard.set(name, forKey: "user_name")
                                                    UserDefaults.standard.set(email, forKey: "user_email")
                                                    userData.username = name
                                                    userData.email = email
                                                    print("userID 저장 완료")
                                                    print("\(userData.username), \(userData.email)")
                                                    UserDefaults.standard.set(true, forKey: "loginSuccessful")
                                                    self.loginSuccessful = true
                                                    print("로그인성공!!!!!!!!!!")
                                                }
                                            }
                                        }
                                    }
                                }
                                task.resume()
                            } else {
                                DispatchQueue.main.async {
                                    self.showingAlert = true  // 로그인 실패 시 알림을 표시
                                }
                            }
                        }
                    }
                    task.resume()
                }) {
                    Text("로그인")
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 100)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(/*@START_MENU_TOKEN@*/.all, 30.0/*@END_MENU_TOKEN@*/)
                .alert(isPresented: $showingAlert) {  // 알림을 표시하는 alert 수정자
                    Alert(title: Text("로그인 실패"), message: Text("이메일과 비밀번호를 다시 확인해주세요."), dismissButton: .default(Text("확인")))
                }
            }
        }
        .padding()
    }
}
