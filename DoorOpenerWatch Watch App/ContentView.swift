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
    @AppStorage("logged_in") var loggedIn: Bool = false
    
    @State private var isPresentingLogoutView = false
    
    var global = Global()
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("\(userName) 님, \n안녕하세요?")
                    .font(.title3)
                    .multilineTextAlignment(.leading)
                    .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                Spacer()
                NavigationLink(destination: Open().environmentObject(global)) {
                    HStack {
                        Image(systemName: "key.horizontal.fill")
                        Text("문 열기")
                    }
                }
                .buttonStyle(BorderedButtonStyle(tint: .yellow))
            }
            .navigationBarTitle("DoorOpener")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingLogoutView.toggle()
                    } label: {
                        Image(systemName:"ellipsis")
                    }
                    .fullScreenCover(isPresented: $isPresentingLogoutView) {
                        LogoutView(isShow: $isPresentingLogoutView)
                    }
                }
            }
        }
    }
}

struct LogoutView: View {
    @Binding var isShow: Bool
    var body: some View {
        Button {
            logout()
        } label: {
            Text("로그아웃")
        }
        .buttonStyle(BorderedButtonStyle(tint: .red))
    }
}

struct OpeningDoorView: View {
    @EnvironmentObject var taptic: Taptic
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(x: 2, y: 2, anchor: .center)
            Text("문을 여는 중입니다...")
                .onAppear {
                    taptic.isTap = true
                }
        }
    }
}

struct DoorOpenedView: View {
    @AppStorage("isTest") var isTest: Bool = false
    @AppStorage("user_name") var userName: String = ""

    
    @EnvironmentObject var taptic: Taptic
    
    
    var body: some View {
        VStack {
            Text("\(userName) 님,\n환영합니다!")
                .font(.title2)
                .padding(.bottom)
            Text("문을 열었습니다.")
                .padding(.top)
            if isTest {
                Text("테스트 모드입니다.\n실제로 문이 열리지 않았습니다.")
            }
        }
        .onAppear {
            if taptic.isTap {
                WKInterfaceDevice.current().play(.success)
                taptic.isTap = false
            }
        }
    }
}

struct Open: View {
    @EnvironmentObject var global: Global
    
    var taptic = Taptic()

    
    var body: some View {
        VStack {
            if global.doorStatus == "Pending" {
                OpeningDoorView().environmentObject(taptic)
            } else if global.doorStatus == "Success" {
                DoorOpenedView().environmentObject(taptic)
            } else {
                Text(global.doorStatus)
            }
        }
        .onAppear(perform: {
            DispatchQueue.main.async {
                global.openDoor()
            }
        })
    }
}


struct SwiftUIView_Previews: PreviewProvider {
    @AppStorage("user_name") var userName: String = ""
    static var previews: some View {
        ContentView()
//        OpeningDoorView()
//            .environmentObject(Taptic())
//        ParentView()
    }
}
