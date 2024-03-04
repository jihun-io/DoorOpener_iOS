//
//  DoorOpenerApp.swift
//  DoorOpener
//
//  Created by 김지훈 on 3/3/24.
//

import SwiftUI

//class UserSettings: ObservableObject {
//    @Published var loginSuccessful: Bool = UserDefaults.standard.bool(forKey: "loginSuccessful")
//}

@main
struct DoorOpenerApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    @StateObject var settings = UserSettings()
    
    
    @StateObject var userData = UserData()
    
    var body: some Scene {
        WindowGroup {
            ParentView()
                .environmentObject(userData)

        }
    }
}
