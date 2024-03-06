//
//  ContentView.swift
//  DoorOpenerWatch Watch App
//
//  Created by 김지훈 on 3/6/24.
//

import SwiftUI

import Foundation
import WatchKit
import WatchConnectivity
import Combine


struct ParentView: View {
//    @StateObject var loginstatus = LoginStatus()
    @AppStorage("logged_in") var loggedIn: Bool = false

    var body: some View {
        VStack {
//            Login()
            if loggedIn {
                ContentView()
            } else {
                Login()
            }
        }
    }
}

struct ContentView: View {
    @AppStorage("user_name") var userName: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("\(userName)님, 환영합니다!")
                    .multilineTextAlignment(.leading)
                    .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                NavigationLink(destination: Open()) {
                    HStack {
                        Image(systemName: "key.horizontal.fill")
                        Text("문 열기")
                    }
                }
                .buttonStyle(BorderedButtonStyle(tint: .yellow))
            }
            .navigationBarTitle("DoorOpener")
        }
    }
}

struct Open: View {
    var body: some View {
        VStack {
//            Text(watchSessionManager.result)
        }
        .onAppear {
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(["request": "startWork"], replyHandler: nil, errorHandler: nil)
            }
        }
    }
}


struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        ParentView()
//        ContentView()
//            .environmentObject(WatchSessionManager())
    }
}
