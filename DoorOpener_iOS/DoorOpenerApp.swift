//
//  DoorOpenerApp.swift
//  DoorOpener
//
//  Created by 김지훈 on 3/3/24.
//

import SwiftUI

@main
struct DoorOpenerApp: App {
    @StateObject private var viewModel = ViewModel()
    
    @StateObject var userData = UserData()
    @StateObject var global = Global() // 이 부분을 수정했습니다.

    var body: some Scene {
        WindowGroup {
            ParentView()
                .environmentObject(userData)
                .environmentObject(viewModel)
                .environmentObject(global)
                .onOpenURL { url in
                    if url.absoluteString == "dooropener://open" {
                        print(url)
                        viewModel.showOpenView = true
                    }
                }

        }
    }
}
