//
//  MainView.swift
//  DoorOpener
//
//  Created by 김지훈 on 3/7/24.
//

import SwiftUI
import Foundation

struct Main: View {
    @EnvironmentObject var global: Global
    @EnvironmentObject var userData: UserData
    
    @AppStorage("isTest") var isTest: Bool = false
    
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
                        if ProcessInfo.processInfo.isMacCatalystApp {
                            Button(action: {
                                self.showingOpen = true
                            }) {
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
                        } else {
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
                                            .foregroundColor(Color.black)
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
                        if isTest {
                            Text("테스트 모드입니다!")
                                .font(.caption)
                                .foregroundColor(Color.gray)
                        }
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
                let remainPercent = -((1 - Double(remainDistance + 67) / 67) * 100) / 3.5
                let remainTime = remainPercent / 100
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + remainTime) {
                    let impactMed = UIImpactFeedbackGenerator(style: .light)
                    impactMed.impactOccurred()
                    showingOpen = true
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                        dragAmount = .zero
                    }
                }
            }
        })
    }
}
