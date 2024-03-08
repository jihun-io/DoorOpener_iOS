//
//  LoginView.swift
//  DoorOpener
//
//  Created by 김지훈 on 3/7/24.
//
import SwiftUI
import Foundation

func LoginProcess(email: String, password: String, userData: UserData) async -> String {
    @AppStorage("openerURL") var openerURL = ""
    var resultofLogin = "Not Logged in yet"

    // 로그인 요청을 보냅니다.
    let loginInfo = "email=\(email)&password=\(password)"
    let loginData = loginInfo.data(using: .utf8)
    let url = URL(string: "\(openerURL)/login")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = loginData
    request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    let config = URLSessionConfiguration.default
    config.httpCookieStorage = HTTPCookieStorage.shared
    let session = URLSession(configuration: config)

    do {
        let (data, response) = try await session.data(for: request)
        let str = String(data: data, encoding: .utf8)

        // 서버의 응답에서 로그인 성공 메시지를 찾습니다.
        if str?.contains("<h1 class=\"status_message\">로그인을<br>완료했습니다.</h1>") == true {
            // 사용자 정보 페이지를 요청합니다.
            let url = URL(string: "\(openerURL)/settings/user")!
            let (data, response) = try await URLSession.shared.data(from: url)
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

                    // 사용자 이름과 이메일을 저장합니다.
                    UserDefaults.standard.set(name, forKey: "user_name")
                    UserDefaults.standard.set(email, forKey: "user_email")
                    userData.username = name
                    userData.email = email
                    print("userID 저장 완료")
                    print("\(userData.username), \(userData.email)")
                    print("로그인성공!!!!!!!!!!")
                    UserDefaults.standard.set(true, forKey: "loginSuccessful")
                    if UserDefaults.standard.bool(forKey: "loginSuccessful") {
                        print("로그인값이 트루다!")
                        await UIApplication.shared.registerForRemoteNotifications()
                        resultofLogin = "Success"
                    } else {
                        resultofLogin = "Failed"
                    }
                }
            }
        }
    } catch {
        print("Error: \(error)")
    }

    return resultofLogin
}


struct LoginParent: View {
    @AppStorage("openerURL") var openerURL = ""
    @Binding var loginSuccessful: Bool
    @State private var isLinkActive = false
    @State private var showAlert = false
    
    @EnvironmentObject var userData: UserData

    
    func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.scheme != nil,
              components.host != nil,
              components.path.isEmpty
        else {
            return false
        }
        return true
    }


    var body: some View {
        NavigationView {
            VStack {
                Text("먼저, 서버의 URL을 입력하십시오.")
                    .padding(.vertical)
                TextField("URL", text: $openerURL)
                    .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.secondarySystemBackground)))
                Button(action: {
                    if isValidURL(openerURL) {
                        isLinkActive = true
                    } else {
                        showAlert = true
                    }
                }) {
                    Text("다음")
                        .padding(.vertical)
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("올바르지 않은 URL"), message: Text("올바른 URL을 입력하십시오."), dismissButton: .default(Text("확인")))
                }
                NavigationLink(destination: Login(loginSuccessful: $loginSuccessful).environmentObject(userData), isActive: $isLinkActive) {
                    EmptyView()
                }
            }
            .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
        }
        .onAppear {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}


struct Login: View {
    @Binding var loginSuccessful: Bool
    @EnvironmentObject var userData: UserData
    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false  // 알림 표시 여부를 결정하는 @State 변수
    @State private var isLoading = false
    
    @AppStorage("openerURL") var openerURL = ""
    
    var body: some View {
        ZStack {
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
                            .keyboardType(/*@START_MENU_TOKEN@*/.emailAddress/*@END_MENU_TOKEN@*/)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.secondarySystemBackground)))
                        
                        SecureField("비밀번호", text: $password)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.secondarySystemBackground)))
                            .submitLabel(.join)
                            .onSubmit {
                                isLoading = true
                                Task {
                                    let result = await LoginProcess(email: email, password: password, userData: userData)
                                    isLoading = false
                                    if result == "Success" {
                                        print("Success!!!! : \(userData.username), \(userData.email)")
                                        
                                        DispatchQueue.main.async {
                                            loginSuccessful = true
                                        }
                                    } else if result == "Not Logged in Yet"{
                                        
                                    } else {
                                        print(result)
                                        showingAlert = true
                                    }
                                }
                            }
                    }
                    
                    Button(action: {
                        isLoading = true
                        Task {
                            let result = await LoginProcess(email: email, password: password, userData: userData)
                            
                            isLoading = false
                            if result == "Success" {
                                print("Success!!!! : \(userData.username), \(userData.email)")
                                
                                DispatchQueue.main.async {
                                    loginSuccessful = true
                                }
                            } else if result == "Not Logged in Yet"{
                                
                            } else {
                                print(result)
                                showingAlert = true
                            }
                        }
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

            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { }
            }
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2)
//                    .opacity(isLoading ? 1 : 0)
            }
        }
    }
}

struct LoginViewPreview: PreviewProvider {
    static var previews: some View {
        @State var loginSuccessful = false
        //        Login(loginSuccessful: $loginSuccessful)
        //        ParentView()
        //        Test()
        //        Settings(loginSuccessful: $loginSuccessful)
        //        OpenLogsView()
        //        Login(loginSuccessful: $loginSuccessful)
        Login(loginSuccessful: $loginSuccessful)
        
        
            .environmentObject(UserData())
            .environmentObject(ViewModel())
            .environmentObject(Global())
            .environmentObject(Taptic())
            .environmentObject(Setup())
            .environmentObject(SyncWithAppleWatch())
    }
}


//Login(loginSuccessful: $loginSuccessful)
