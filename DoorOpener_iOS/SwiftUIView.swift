//
//  SwiftUIView.swift
//  DoorOpener
//
//  Created by 김지훈 on 3/3/24.
//

import SwiftUI
import Foundation
import WatchConnectivity
import Combine



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
                LoginParent(loginSuccessful: $loginSuccessful)
            }
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: "loginSuccessful") {
                print("로그인값이 트루다!")
                UIApplication.shared.registerForRemoteNotifications()
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
    }
}

struct LoginWithAppleWatch: View {
    @EnvironmentObject var syncwithapplewatch: SyncWithAppleWatch
    @AppStorage("watchLogin") var watchLogin: Bool = false
    
    var body: some View {
        VStack {
            if !watchLogin {
                AWLoading()
            } else {
                AWComplete()
            }
        }
        .navigationBarTitle("Apple Watch에 로그인", displayMode: .inline)
        .onAppear {
            syncwithapplewatch.complete = false
        }
    }
}

struct AWLoading: View {
    @EnvironmentObject var syncwithapplewatch: SyncWithAppleWatch
    @StateObject var applewatchconnect = WatchConnectManager()
    @AppStorage("watchLogin") var watchLogin: Bool = false

    @State var isGet = false
    @State var token = ""
    
    @AppStorage("openerURL") var openerURL: String = ""


    var body: some View {
        VStack {
            ProgressView()
                .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                .progressViewStyle(LargeProgressViewStyle())
            Text("Apple Watch와 계정을 연동 중입니다...")
                .onAppear {
                    loadToken(from: "\(openerURL)/applewatch/generate") { pText in
                        if let pText = pText {
                            isGet = true
                            token = pText
                            print(token)
                            applewatchconnect.sendMessage(token)
                        }
                    }
                }
                .onReceive(applewatchconnect.$receivedMessage) { newValue in
                    print("Received: \(newValue)")
                    if newValue != "" {
                        print("Received: \(newValue)")
                        syncwithapplewatch.complete = true
                        watchLogin = true
                    }
                }
        }
    }
}

struct AWComplete: View {
    @EnvironmentObject var syncwithapplewatch: SyncWithAppleWatch
    @AppStorage("watchLogin") var watchLogin: Bool = false
    
    var body: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                .scaledToFill()
                .frame(width: 100, height: 100)
            Text("연동이 완료되었습니다.")
                .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            
            if !syncwithapplewatch.complete {
                Button(action: {
                    syncwithapplewatch.complete = false
                    watchLogin = false
                    
                }, label: {
                    Text("다시 로그인하기")
                        .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                })
            }
            
        }
    }
}



struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        @State var loginSuccessful = false
        //        Login(loginSuccessful: $loginSuccessful)
        ParentView()
        //        Test()
//        AWComplete()
            .environmentObject(UserData())
            .environmentObject(ViewModel())
            .environmentObject(Global())
            .environmentObject(Taptic())
            .environmentObject(Setup())
            .environmentObject(SyncWithAppleWatch())
            .onOpenURL { url in
                if url.absoluteString == "dooropener://open" {
                    print(url)
                    ViewModel().showOpenView = true
                }
            }
    }
}
