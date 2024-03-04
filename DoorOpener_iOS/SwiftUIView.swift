//
//  SwiftUIView.swift
//  DoorOpener
//
//  Created by 김지훈 on 3/3/24.
//

import SwiftUI

class Global: ObservableObject {
    func userInfoLoad() {
        print("테스트!!")
    }
}

struct Login: View {
    @Binding var loginSuccessful: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false  // 알림 표시 여부를 결정하는 새로운 @State 변수
    
    var body: some View {
        VStack {
            if loginSuccessful {
                ParentView()
            } else {
                Text("DoorOpener")
                    .font(.title)
                    .fontWeight(.black)
                
                TextField("이메일", text: $email)
                    .padding()
                    .border(Color.gray, width: 0.5)
                
                SecureField("비밀번호", text: $password)
                    .padding()
                    .border(Color.gray, width: 0.5)
                
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
                                                    print("userID 저장 완료!!!!!!!!!!!!!!!!!!!")
                                                    self.loginSuccessful = true
                                                    UserDefaults.standard.set(true, forKey: "loginSuccessful")
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
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .alert(isPresented: $showingAlert) {  // 알림을 표시하는 alert 수정자
                    Alert(title: Text("로그인 실패"), message: Text("로그인이 실패했습니다."), dismissButton: .default(Text("확인")))
                }
            }
        }
        .padding()
    }
}

struct ParentView: View {
    @EnvironmentObject var global: Global
    
    @State private var loginSuccessful = UserDefaults.standard.bool(forKey: "loginSuccessful")
    
    @State private var userName = UserDefaults.standard.string(forKey: "user_name") ?? "Unknown"
    @State private var userEmail = UserDefaults.standard.string(forKey: "user_email") ?? "Unknown"
    
    
    var body: some View {
        if loginSuccessful {
            ContentView(loginSuccessful: $loginSuccessful, userName: $userName, userEmail: $userEmail)
        } else {
            Login(loginSuccessful: $loginSuccessful)
        }
    }
    
    init() {
        global.userInfoLoad()
    }
}


struct ContentView: View {
    @Binding var loginSuccessful: Bool
    
    @Binding var userName: String
    @Binding var userEmail: String
    
    var body: some View {
        TabView {
            Main(userName: $userName, userEmail: $userEmail)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
            
            Settings(loginSuccessful: $loginSuccessful, userName: $userName, userEmail: $userEmail)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("설정")
                }
        }
        
    }
}

struct Main: View {
    @State private var loginSuccessful = UserDefaults.standard.bool(forKey: "loginSuccessful")
    
    @Binding var userName: String
    @Binding var userEmail: String
    
    var body: some View {
        
        NavigationView {
            ZStack {
                Color(UIColor.systemGray6).ignoresSafeArea()
                
                VStack {
                    Text("\(userName) 님,\n안녕하세요?")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.all)
                        .frame(width: 200.0)
                    Spacer()
                        .frame(height: 50)
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "key.horizontal.fill")
                            Text("문 열기")
                        }
                        
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(10)
                        .navigationBarTitle("DoorOpener")
                    }
                    .padding(.all)
                }
                .padding(.all, 15)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                
            }
        }
        
    }
}


struct Settings: View {
    //    @State private var loginSuccessful = UserDefaults.standard.bool(forKey: "loginSuccessful")
    @Binding var loginSuccessful: Bool
    
    @Binding var userName: String
    @Binding var userEmail: String
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    NavigationLink(destination: EditUser(userName: $userName, userEmail: $userEmail)) {
                        VStack(alignment: .leading) {
                            Text(userName)
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                            
                            Text("사용자 정보 변경")
                        }
                    }
                }
                
                Button(action: {
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
                                print("로그아웃 완료!!!")
                            }
                        }
                    }
                    task.resume()
                }) {
                    Text("로그아웃")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
            .navigationBarTitle("설정")
        }
        
    }
}

struct EditUser: View {
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
                    self.userName = name // @State 프로퍼티를 업데이트합니다.
                    self.userEmail = email // @State 프로퍼티를 업데이트합니다.
                    print("사용자 정보 업데이트 완료: \(userName), \(userEmail)")
                    
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

#Preview {
    ParentView() //이거임
    //    Settings()
}
