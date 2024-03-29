//
//  DoorOpenerApp.swift
//  DoorOpener
//
//  Created by 김지훈 on 3/3/24.
//

import SwiftUI
import WatchConnectivity
import UserNotifications

@main
struct DoorOpenerApp: App {
    @StateObject private var viewModel = ViewModel()
    
    @StateObject var userData = UserData()
    @StateObject var global = Global()
    @StateObject var syncwithapplewatch = SyncWithAppleWatch()
    @StateObject var setup = Setup()
    @StateObject var taptic = Taptic()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ParentView()
                .environmentObject(userData)
                .environmentObject(viewModel)
                .environmentObject(global)
                .environmentObject(setup)
                .environmentObject(taptic)
                .environmentObject(syncwithapplewatch)
                .onOpenURL { url in
                    if url.absoluteString == "dooropener://open" {
                        print(url)
                        viewModel.showOpenView = true
                    }
                }

        }
    }
}
