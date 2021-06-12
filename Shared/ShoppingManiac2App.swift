//
//  ShoppingManiac2App.swift
//  Shared
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI

@main
struct ShoppingManiac2App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
