//
//  SettingsView.swift
//  DoorOpener
//
//  Created by 김지훈 on 3/7/24.
//

import SwiftUI
import Foundation

struct Settings: View {
    @State private var showingLogoutAlert = false
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var setup: Setup
    
    @AppStorage("isTest") var isTest: Bool = false
    
    @Binding var loginSuccessful: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section {
                        NavigationLink(destination: EditUser(userName: $userData.username, userEmail: $userData.email).environmentObject(userData)) {
                            VStack(alignment: .leading) {
                                Text(userData.username)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.leading)
                                
                                Text("사용자 정보 변경")
                            }
                        }
                    }
                    if ProcessInfo.processInfo.isMacCatalystApp {

                    } else {
                        Section {
                            NavigationLink(destination: LoginWithAppleWatch()) {
                                Text("Apple Watch에 로그인")
                            }
                        }
                    }
                    //                        NavigationLink(destination: Text("Hello, world!")) {
                    //                            Text("임시 키 발급")
                    //                        }
                    //                        NavigationLink(destination: Text("Hello, world!")) {
                    //                            Text("잠금 해제 기록")
                    //                        }
                    //                    }
                    //                    Section {
                    //                        NavigationLink(destination: Text("Hello, world!")) {
                    //                            Text("단축어 앱에 추가")
                    //                        }
                    //                    }
                    //                    Section {
                    //                        NavigationLink(destination: Text("Hello, world!")) {
                    //                            Text("시스템 정보")
                    //                        }
                    //                    }
//                    Section {
//                        NavigationLink(destination: TokenTest()) {
//                            Text("알림 토큰 확인하기")
//                        }
//                    }
                    
                    Section {
                        Toggle("테스트 모드", isOn: $isTest)
                    }
                    Section {
                        Button(action: {
                            self.showingLogoutAlert = true
                        }) {
                            Text("로그아웃")
                                .foregroundColor(.red)
                        }
                        .alert(isPresented: $showingLogoutAlert) {
                            Alert(title: Text("로그아웃"), message: Text("정말로 로그아웃 하시겠습니까?"), primaryButton: .destructive(Text("로그아웃")) {
                                // 로그아웃 요청을 보냅니다.
                                let url = URL(string: "https://dooropener.jihun.io/logout")!
                                var request = URLRequest(url: url)
                                request.httpMethod = "GET"
                                let session = URLSession(configuration: .default)
                                let task = session.dataTask(with: request) { (data, response, error) in
                                    if let error = error {
                                        print("Error: \(error)")
                                    } else {
                                        DispatchQueue.main.async {
                                            self.loginSuccessful = false
                                            UserDefaults.standard.set(false, forKey: "loginSuccessful")  // 로그인 상태를 저장합니다.
                                            userData.email = ""
                                            userData.username = ""
                                            print("로그아웃 완료!!!")
                                        }
                                    }
                                }
                                task.resume()
                            }, secondaryButton: .cancel())
                        }
                    }
                }
            }
            .navigationBarTitle("설정")
        }
    }
}

struct EditUser: View {
    @EnvironmentObject var userData: UserData
    
    @Binding var userName: String
    @Binding var userEmail: String
    
    @State private var userNameT: String
    @State private var userEmailT: String
    
    @State private var showingAlert = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    init(userName: Binding<String>, userEmail: Binding<String>) {
        _userName = userName
        _userEmail = userEmail
        _userNameT = State(initialValue: userName.wrappedValue)
        _userEmailT = State(initialValue: userEmail.wrappedValue)
    }
    //
    //    var userNameT = userData.username
    //    var userEmailT = userData.email
    
    var body: some View {
        VStack {
            List {
                Section {
                    NavigationLink(destination: ModifyName(text: $userNameT)) {
                        HStack {
                            Text("이름")
                            Spacer()
                            Text(userNameT)
                        }
                    }
                    NavigationLink(destination: ModifyEmail(text: $userEmailT)) {
                        HStack {
                            Text("이메일")
                            Spacer()
                            Text(userEmailT)
                        }
                    }
                }
                Section {
                    NavigationLink(destination: ModifyPassword()) {
                        Text("비밀번호 변경")
                    }
                }
                Section {
                    Button(action: {
                        self.showingAlert = true
                    }) {
                        Text("사용자 삭제")
                            .foregroundColor(.red)
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(
                            title: Text("계정 삭제"),
                            message: Text("정말로 계정을 삭제하시겠습니까?"),
                            primaryButton: .destructive(Text("삭제")) {
                                print("계정 삭제")
                            },
                            secondaryButton: .cancel(Text("취소"))
                        )
                    }
                }
            }
            
        }
        .background(Color(UIColor.systemGray6))
        .navigationBarTitle("사용자 정보", displayMode: .inline)
        .navigationBarItems(trailing: Button("완료") {
            sendPostRequest()
        })
    }
    func sendPostRequest() {
        guard let url = URL(string: "https://dooropener.jihun.io/settings/user/modify/request") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = ["username": userNameT, "email": userEmailT]
        request.httpBody = parameters.percentEncoded()
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
            } else {
                updateUserInfo()
                
            }
        }.resume()
    }
    
    
    func updateUserInfo() {
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
                    userData.username = name // @State 프로퍼티를 업데이트합니다.
                    userData.email = email // @State 프로퍼티를 업데이트합니다.
                    print("사용자 정보 업데이트 완료: \(userData.username), \(userData.email)")
                    
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }.resume()
    }
    
}

extension Dictionary {
    func percentEncoded() -> Data? {
        return map { (key, value) in
            let escapeAllowed = CharacterSet(charactersIn: "=+&").inverted
            let keyString = "\(key)".addingPercentEncoding(withAllowedCharacters: escapeAllowed) ?? ""
            let valueString = "\(value)".addingPercentEncoding(withAllowedCharacters: escapeAllowed) ?? ""
            return keyString + "=" + valueString
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

struct ModifyName: View {
    @Binding var text: String
    @State private var tempText: String
    
    init(text: Binding<String>) {
        _text = text
        _tempText = State(initialValue: text.wrappedValue)
    }
    
    var body: some View {
        List {
            HStack {
                TextField("", text: $text)
                if !text.isEmpty {
                    Button(action: {
                        self.text = ""
                    }) {
                        Image(systemName: "multiply.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .background(Color(UIColor.systemGray6))
        .navigationBarTitle("이름", displayMode: .inline)
        .onDisappear {
            if text.isEmpty {
                text = tempText
            }
        }
    }
}

struct ModifyEmail: View {
    @Binding var text: String
    @State private var tempText: String
    
    init(text: Binding<String>) {
        _text = text
        _tempText = State(initialValue: text.wrappedValue)
    }
    
    var body: some View {
        List {
            HStack {
                TextField("", text: $text)
                if !text.isEmpty {
                    Button(action: {
                        self.text = ""
                    }) {
                        Image(systemName: "multiply.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .background(Color(UIColor.systemGray6))
        .navigationBarTitle("이메일", displayMode: .inline)
        .onDisappear {
            if text.isEmpty {
                text = tempText
            }
        }
    }
}



struct ModifyPassword: View {
    @State var password: String = ""
    @State var password2: String = ""
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    
    enum AlertType: Identifiable {
        case emptyPassword, passwordMismatch
        
        var id: Int {
            switch self {
            case .emptyPassword:
                return 1
            case .passwordMismatch:
                return 2
            }
        }
    }

    @State private var alertType: AlertType?
    
    var body: some View {
        VStack {
            List {
                VStack {
                    HStack {
                        Text("신규")
                        Spacer()
                            .padding(.trailing)
                        SecureField("비밀번호", text: $password)
                            .frame(width: 200.0)
                    }
                }
                VStack {
                    HStack {
                        Text("재확인")
                        Spacer()
                            .padding(.trailing)
                        SecureField("비밀번호 재확인", text: $password2)
                            .frame(width: 200.0)
                    }
                }
            }
        }
        .background(Color(UIColor.systemGray6))
        .navigationBarTitle("비밀번호 변경", displayMode: .inline)
        .navigationBarItems(trailing: Button("완료") {
            sendPostRequest()
        })
        .alert(item: $alertType) { alertType in
            switch alertType {
            case .emptyPassword:
                return Alert(title: Text("비밀번호 변경 실패"), message: Text("비밀번호를 입력하십시오."), dismissButton: .default(Text("확인")))
            case .passwordMismatch:
                return Alert(title: Text("비밀번호 변경 실패"), message: Text("비밀번호가 동일하지 않습니다."), dismissButton: .default(Text("확인")))
            }
        }
    }
    func sendPostRequest() {
        if password.isEmpty {
            self.alertType = .emptyPassword
        } else {
            if password == password2 {
                guard let url = URL(string: "https://dooropener.jihun.io/settings/user/password/request") else {
                    print("Invalid URL")
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                
                let parameters: [String: Any] = ["password": password]
                request.httpBody = parameters.percentEncoded()
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Error: \(error)")
                    } else {
                        DispatchQueue.main.async {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }.resume()
            } else {
                self.alertType = .passwordMismatch
            }
        }
    }
}

struct TokenTest: View {
    var body: some View {
        Group {
            Text("Hello, world!")
        }
        .onAppear {
            
        }
    }

}
