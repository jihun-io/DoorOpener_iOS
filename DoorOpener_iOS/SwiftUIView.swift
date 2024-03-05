//
//  SwiftUIView.swift
//  DoorOpener
//
//  Created by 김지훈 on 3/3/24.
//

import SwiftUI

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
                    
                    DispatchQueue.main.async {
                        self.doorStatus = doorOpenMessage
                        print("문 상태 업데이트 완료: \(self.doorStatus)")
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

struct ParentView: View {
    @EnvironmentObject var global: Global
    @EnvironmentObject var userData: UserData
    
    @EnvironmentObject var viewModel: ViewModel
    
    @Environment(\.openURL) var openURL
    @Environment(\.scenePhase) var scenePhase
    
    @State private var loginSuccessful = UserDefaults.standard.bool(forKey: "loginSuccessful")
    
    @State private var sheetID = 0
    
    var body: some View {
        Group {
            if loginSuccessful {
                ContentView(loginSuccessful: $loginSuccessful)
                    .environmentObject(userData)
                    .sheet(isPresented: $viewModel.showOpenView) {
                        Open().environmentObject(userData)
                    }
            } else {
                Login(loginSuccessful: $loginSuccessful)
            }
        }
    }
}







struct ContentView: View {
    @EnvironmentObject var global: Global
    @EnvironmentObject var userData: UserData
    
    
    @Binding var loginSuccessful: Bool
    
    
    @State private var myUserName = ""
    @State private var myUserEmail = ""
    
    var body: some View {
        Group {
            TabView {
                Main().environmentObject(userData)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("홈")
                    }
                
                Settings(loginSuccessful: $loginSuccessful).environmentObject(userData)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("설정")
                    }
            }
            
        }
        .onAppear(perform: {
            //            global.userInfoLoad()
        })
        
    }
}

struct Main: View {
    @EnvironmentObject var global: Global
    @EnvironmentObject var userData: UserData
    
    @State private var showingOpen = false
    @State private var animStart = false
    @State private var lastLocation = CGSize.zero
    @State private var animEnd = false
    @State private var remainDistance = 0.0
    
    @State private var loginSuccessful = UserDefaults.standard.bool(forKey: "loginSuccessful")
    
    @State private var dragAmount = CGSize.zero
    
    
    var body: some View {
        Group {
            NavigationView {
                ZStack {
                    VStack {
                        Text("\(userData.username) 님,\n안녕하세요?")
                            .onReceive(userData.$username) { _ in }
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.all)
                            .frame(width: 200.0)
                        Spacer()
                            .frame(height: 50)
                        HStack {
                            ZStack {
                                HStack {
                                    Spacer()
                                    Text("밀어서 잠금 해제")
                                        .fontWeight(.bold)
                                        .multilineTextAlignment(.center)
                                        .padding(.trailing, 20.0)
                                        .opacity(1 - Double(dragAmount.width / 70))
                                    
                                }
                                .frame(width: 200.0)
                                HStack {
                                    Image(systemName: "arrowshape.right.fill")
                                        .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                                        .fontWeight(.bold)
                                        .background(Color(.systemYellow))
                                        .cornerRadius(10)
                                        .offset(x: dragAmount.width, y: 0)
                                        .gesture(
                                            DragGesture()
                                                .onChanged {
                                                    self.dragAmount = CGSize(width: min( max($0.translation.width, 0), 147), height: 0)
                                                }
                                                .onEnded { value in
                                                    if dragAmount.width > 80 {
                                                        self.animStart = true
                                                        
                                                    } else if value.predictedEndLocation.x > 147 {
                                                        //                                                        print(value.predictedEndLocation.x)
                                                    }
                                                    withAnimation {
                                                        remainDistance = -dragAmount.width + 147
                                                        lastLocation = dragAmount
                                                        if animStart == true {
                                                            if dragAmount.width == 147 {
                                                                animEnd = true
                                                            } else {
                                                                self.dragAmount = CGSize(width: 147, height: 0)
                                                                animEnd = true
                                                            }
                                                        } else {
                                                            self.dragAmount = .zero
                                                        }
                                                    }
                                                }
                                        )
                                    Spacer()
                                }
                                .frame(width: 200.0)
                            }
                        }
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                        .padding(.all)
                    }
                    .padding(.all, 15)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .sheet(isPresented: $showingOpen) {
                        Open().environmentObject(userData)
                    }
                }
                .background(Color(UIColor.systemBackground))
                .navigationBarTitle("DoorOpener")
            }
        }
        .onChange (of: self.animEnd, perform: { value in
            if value == true {
                self.animStart = false
                self.animEnd = false
                //                print("lastLocation: \(lastLocation)")
                //                Double(dragAmount.width / 70)
                //                print("remainDistance: \(remainDistance)")
                let remainPercent = -((1 - Double(remainDistance + 67) / 67) * 100) / 3.5
                let remainTime = remainPercent / 100
                print ("추가 시간: \(remainTime)")
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + remainTime) {
                    let impactMed = UIImpactFeedbackGenerator(style: .light)
                    impactMed.impactOccurred()
                
                    showingOpen = true
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                        dragAmount = .zero
                    }
                    
                }
                //                print("animStart: \(animStart), animEnd: \(animEnd)")
                
            }
        })
        
    }
}


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
                    //                    Section {
                    //                        NavigationLink(destination: Text("Hello, world!")) {
                    //                            Text("사용자 초대")
                    //                        }
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
                    //                        NavigationLink(destination: Test()) {
                    //                            Text("슬라이더 테스트")
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

struct LargeProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ProgressView(configuration)
            .scaleEffect(2) // 크기를 2배로 조절합니다.
    }
}

struct OpeningDoorView: View {
    @EnvironmentObject var taptic: Taptic
    var body: some View {
        VStack {
            ProgressView()
                .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                .progressViewStyle(LargeProgressViewStyle())
            Text("문을 여는 중입니다...")
                .onAppear {
                    taptic.isTap = true
//                    print(taptic.isTap)
                }
        }
    }
}

struct DoorOpenedView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userData: UserData
    
    @AppStorage("isTest") var isTest: Bool = false
    
    @EnvironmentObject var taptic: Taptic
    
    
    var body: some View {
        let nameGet = userData.username
        Group {
            ZStack {
                VStack {
                    Spacer()
                    VStack {
                        Image(systemName: "door.left.hand.open")
                            .resizable()
                            .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                        Text("\(nameGet) 님,\n환영합니다!")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.all)
                            .frame(width: 200.0)
                        
                        Text("문을 성공적으로 열었습니다.")
                            .padding(.all)
                        if isTest {
                            Text("테스트 모드입니다.\n실제로 문이 열리지 않았습니다.")
                                .font(.caption)
                                .foregroundColor(Color.gray)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.all, 15)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    Spacer()
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("닫기")
                            .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                    })
                }
            }
            .background(Color(UIColor.systemBackground))
        }
        .onAppear {
//            print(taptic.isTap)
            if taptic.isTap {
                let impactMed = UIImpactFeedbackGenerator(style: .heavy)
                impactMed.impactOccurred()
                taptic.isTap = false
                
            }
            
        }
    }
}



struct Open: View {
    @EnvironmentObject var global: Global
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        VStack {
            if global.doorStatus == "문을 여는 중입니다..." {
                OpeningDoorView()
            } else if global.doorStatus == "문을 열었습니다." {
                DoorOpenedView().environmentObject(userData)
            } else {
                Text(global.doorStatus)
            }
        }
        .onAppear(perform: {
            DispatchQueue.main.async {
                global.openDoor()
            }
        })
        //        .onAppear(perform: {
        //            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        //                global.openDoor()
        //            }
        //        })
    }
}

//struct Test: View {
//
//    var body: some View {
//        VStack {
//
//        }
//        .navigationBarTitle("사용자 정보", displayMode: .inline)
//
//    }
//}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        @State var loginSuccessful = false
        //        Login(loginSuccessful: $loginSuccessful)
        ParentView()
        //        Test()
            .environmentObject(UserData())
            .environmentObject(ViewModel())
            .environmentObject(Global())
            .environmentObject(Taptic())
            .environmentObject(Setup())
            .onOpenURL { url in
                if url.absoluteString == "dooropener://open" {
                    print(url)
                    ViewModel().showOpenView = true
                }
            }
    }
}
