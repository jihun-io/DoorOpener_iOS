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
    }
}

struct LoginWithAppleWatch: View {
    @EnvironmentObject var syncwithapplewatch: SyncWithAppleWatch
    var body: some View {
        VStack {
            if !syncwithapplewatch.complete {
                AWLoading()
            } else {
                AWComplete()
            }
        }
        .navigationBarTitle("Apple Watch에 로그인", displayMode: .inline)

    }
}

struct AWLoading: View {
    @EnvironmentObject var syncwithapplewatch: SyncWithAppleWatch
    @StateObject var applewatchconnect = WatchConnectManager()
    @State var isGet = false
    @State var token = ""

    var body: some View {
        VStack {
            ProgressView()
                .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                .progressViewStyle(LargeProgressViewStyle())
            Text("Apple Watch와 계정을 연동 중입니다...")
                .onAppear {
                    loadToken(from: "https://dooropener.jihun.io/applewatch/generate") { pText in
                        if let pText = pText {
                            isGet = true
                            token = pText
                            print(token)
                            applewatchconnect.sendMessage(token)
                        }
                    }
                }
        }
    }
}

struct AWComplete: View {

    var body: some View {
        VStack {
            Text("연동이 완료되었습니다!")
        }
    }
}



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
            .environmentObject(SyncWithAppleWatch())
            .onOpenURL { url in
                if url.absoluteString == "dooropener://open" {
                    print(url)
                    ViewModel().showOpenView = true
                }
            }
    }
}
