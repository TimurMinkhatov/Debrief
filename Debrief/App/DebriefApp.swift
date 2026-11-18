//
//  DebriefApp.swift
//  Debrief
//
//  Created by Timur Minkhatov on 10/09/2026.
//

import SwiftUI
import SwiftData
import DebriefData
import FirebaseCore
import FirebaseAppCheck

@main
struct DebriefApp: App {
    init() {
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #endif
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: DebriefSchema.models)
    }
}
