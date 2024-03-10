//
//  SettingsView.swift
//  DoorOpener
//
//  Created by 김지훈 on 3/7/24.
//

import SwiftUI
import Foundation
import SafariServices

import SwiftSoup

struct Log: Identifiable {
    let id = UUID()
    let name: String
    let date: String
    let path: String
}

func fetchLogs() async -> [Log] {
    @AppStorage("openerURL") var openerURL: String = ""

    guard let url = URL(string: "\(openerURL)/settings/logs") else { return [] }
    let dataResponse = try? await URLSession.shared.data(from: url)
    var logs: [Log] = []
    if let data = dataResponse?.0 {
        let html = String(data: data, encoding: .utf8)
        do {
            let doc: Document = try SwiftSoup.parse(html ?? "")
            let elements: Elements = try doc.select("tbody tr")
            for element in elements.array() {
                let tds = try element.select("td").array()
                if tds.count >= 3 {
                    let name = try tds[0].text()
                    let date = try tds[1].text()
                    let path = try tds[2].text()
                    logs.append(Log(name: name, date: date, path: path))
                }
                if logs.count >= 100 {
                    break
                }
            }
        } catch Exception.Error(let type, let message) {
            print(type, message)
        } catch {
            print("error")
        }
    }
    return logs
}

func sendPush() async -> String {
    @AppStorage("openerURL") var openerURL: String = ""
    
    guard let url = URL(string: "\(openerURL)/pushtest") else { return "Error" }
    return "Completed"
}


struct Settings: View {
    @State private var showingLogoutAlert = false
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var setup: Setup

    @Binding var loginSuccessful: Bool
    
    @AppStorage("openerURL") var openerURL: String = ""
    @AppStorage("isAdmin") var isAdmin: Bool = false

    
    @State var showShortcuts = false
    @State var urlString = "https://www.icloud.com/shortcuts/de4a01d269764d7ca2f1f8f4ca29df7b"

    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section {
                        NavigationLink(destination: EditUser(userName: $userData.username, userEmail: $userData.email).environmentObject(userData)) {
                            VStack(alignment: .leading) {
                                Text(userData.username)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.leading)
                                
                                Text("사용자 정보 변경")
                            }
                        }
                    }
                    Section {
                        NavigationLink(destination: OpenLogsView()) {
                            Text("잠금 해제 기록")
                        }
                    }
                    if ProcessInfo.processInfo.isMacCatalystApp {

                    } else {
                        Section {
                            Button(action: {
                                self.showShortcuts = true
                            }) {
                                Text("단축어 앱에 추가")
                            }
                            
                            NavigationLink(destination: LoginWithAppleWatch()) {
                                Text("Apple Watch에 로그인")
                            }
                        }
                    }
                    if isAdmin {
                        Section {
                            NavigationLink(destination: Dev()) {
                                Text("개발자 설정")
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
                                let url = URL(string: "\(openerURL)/logout")!
                                var request = URLRequest(url: url)
                                request.httpMethod = "GET"
                                let session = URLSession(configuration: .default)
                                let task = session.dataTask(with: request) { (data, response, error) in
                                    if let error = error {
                                        print("Error: \(error)")

                                        // 로그인 정보 초기화
                                        self.loginSuccessful = false
                                        UserDefaults.standard.set(false, forKey: "loginSuccessful")
                                        userData.email = ""
                                        userData.username = ""
                                    } else {
                                        DispatchQueue.main.async {
                                            // 로그인 정보 초기화
                                            self.loginSuccessful = false
                                            UserDefaults.standard.set(false, forKey: "loginSuccessful")
                                            userData.email = ""
                                            userData.username = ""
                                            print("로그아웃 완료")
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
        .sheet(isPresented: $showShortcuts) {
            Shortcuts(url:URL(string: self.urlString)!)
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
        @AppStorage("openerURL") var openerURL: String = ""

        guard let url = URL(string: "\(openerURL)/settings/user/modify/request") else {
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
        @AppStorage("openerURL") var openerURL: String = ""

        guard let url = URL(string: "\(openerURL)/settings/user") else {
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
                    .keyboardType(/*@START_MENU_TOKEN@*/.emailAddress/*@END_MENU_TOKEN@*/)
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
        @AppStorage("openerURL") var openerURL: String = ""

        if password.isEmpty {
            self.alertType = .emptyPassword
        } else {
            if password == password2 {
                guard let url = URL(string: "\(openerURL)/settings/user/password/request") else {
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

struct OpenLogsView: View {
    @State private var logsComplete = false
    @State private var logs: [Log] = []

    var body: some View{
        Group {
            if !logsComplete {
                OpenLogsLoading()
            } else {
                OpenLogs(logs: $logs)
            }
        }
        .navigationBarTitle("잠금 해제 기록", displayMode: .inline)
        .onAppear {
            Task {
                self.logs = await fetchLogs()
                self.logsComplete = true
            }
        }
    }
}

struct OpenLogsLoading: View {
    var body: some View{
        VStack {
            ProgressView()
                .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                .progressViewStyle(LargeProgressViewStyle())
            Text("불러오는 중...")
        }
    }
}

struct OpenLogs: View {
    @Binding var logs: [Log]
    var body: some View {
        Group {
//            Text("최근 100개의 기록까지만 열람할 수 있습니다.")
            List {
                Section(header: Text("최근 100개의 기록까지만 열람할 수 있습니다.")){
                    ForEach(logs) { log in
                        VStack {
                            HStack {
                                Text(log.name)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            HStack {
                                Text(log.date)
                                    .monospacedDigit()
                                Spacer()
                                Text(log.path)
                            }
                        }
                    }
                }
            }
        }
        .refreshable {
            await refresh()
        }
    }
    
    func refresh() async {
        self.logs = await fetchLogs()
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

struct Dev: View {
    @AppStorage("openerURL") var openerURL: String = ""
    @AppStorage("isTest") var isTest: Bool = false
    @AppStorage("noNotification") var noNotification: Bool = false
    var body: some View {
        List {
            Section {
                Toggle("테스트 모드", isOn: $isTest)
                if isTest {
                    Toggle("조용히 문 열기", isOn: $noNotification)
                }

            }
            Section {
                Button(action: {
                    Task {
                        await sendPush()
                    }
                }) {
                    Text("모든 관리자 계정에게 알림 전송")
                }
            }
        }
        .navigationBarTitle("개발자 설정", displayMode: .inline)

    }
}

struct Shortcuts: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<Shortcuts>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<Shortcuts>) {

    }

}

struct SettingsViewPreview: PreviewProvider {
    static var previews: some View {
        @State var loginSuccessful = false
        //        Login(loginSuccessful: $loginSuccessful)
//        ParentView()
        //        Test()
        Settings(loginSuccessful: $loginSuccessful)
//        OpenLogsView()
            .environmentObject(UserData())
            .environmentObject(ViewModel())
            .environmentObject(Global())
            .environmentObject(Taptic())
            .environmentObject(Setup())
            .environmentObject(SyncWithAppleWatch())
    }
}
