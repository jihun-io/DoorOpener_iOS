//
//  OpenView.swift
//  DoorOpener
//
//  Created by 김지훈 on 3/7/24.
//
import SwiftUI
import Foundation

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
    }
}
