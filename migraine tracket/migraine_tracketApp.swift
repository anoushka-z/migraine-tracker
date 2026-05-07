//
//  migraine_tracketApp.swift
//  migraine tracket
//
//  Created by Anoushka Shresth on 07/05/26.
//

import SwiftUI
import SwiftData

@main
struct migraine_tracketApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [MigraineEntry.self, MedicationDose.self, AppSettings.self])
    }
}
