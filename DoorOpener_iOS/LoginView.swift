//
//  LoginView.swift
//  DoorOpener
//
//  Created by 김지훈 on 3/7/24.
//
import SwiftUI
import Foundation

struct LoginData: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let result: String
    let username: String
    let email: String
    let isAdmin: Int?
}

func LoginProcess(email: String, password: String, userData: UserData) async -> String {
    @AppStorage("openerURL") var openerURL = ""
    @AppStorage("isAdmin") var isAdmin: Bool = false
    
    @AppStorage("isTest") var isTest: Bool = false
    @AppStorage("noNotification") var noNotification: Bool = false
    
    
    var resultofLogin = "Not Logged in yet"

    let loginData = LoginData(email: email, password: password)
    guard let jsonData = try? JSONEncoder().encode(loginData) else { return resultofLogin }
    
    let url = URL(string: "\(openerURL)/loginwithapp")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let config = URLSessionConfiguration.default
    config.httpCookieStorage = HTTPCookieStorage.shared
    let session = URLSession(configuration: config)

    do {
        let (data, response) = try await session.data(for: request)

        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        if loginResponse.result == "Success" {
            UserDefaults.standard.set(loginResponse.username, forKey: "user_name")
            UserDefaults.standard.set(loginResponse.email, forKey: "user_email")
            userData.username = loginResponse.username
            userData.email = loginResponse.email
            
            if loginResponse.isAdmin != nil {
                isAdmin = true
            } else {
                isAdmin = false
                isTest = false
                noNotification = false
            }
            

            print("userData 저장 완료")
            print("\(userData.username), \(userData.email), \(isAdmin)")
            print("로그인 성공!")
            UserDefaults.standard.set(true, forKey: "loginSuccessful")
            if UserDefaults.standard.bool(forKey: "loginSuccessful") {
                print("로그인값이 트루다!")
                await UIApplication.shared.registerForRemoteNotifications()
                resultofLogin = "Success"
            } else {
                resultofLogin = "Failed"
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
                Text("DoorOpener")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .padding(/*@START_MENU_TOKEN@*/.all, 30.0/*@END_MENU_TOKEN@*/)
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
                            .textContentType(.emailAddress)
                            .keyboardType(/*@START_MENU_TOKEN@*/.emailAddress/*@END_MENU_TOKEN@*/)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.secondarySystemBackground)))
                        
                        SecureField("비밀번호", text: $password)
                            .padding()
                            .textContentType(.password)
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
        LoginParent(loginSuccessful: $loginSuccessful)
        
        
            .environmentObject(UserData())
            .environmentObject(ViewModel())
            .environmentObject(Global())
            .environmentObject(Taptic())
            .environmentObject(Setup())
            .environmentObject(SyncWithAppleWatch())
    }
}


//Login(loginSuccessful: $loginSuccessful)
