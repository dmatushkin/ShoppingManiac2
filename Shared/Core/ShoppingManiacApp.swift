//
//  ShoppingManiac2App.swift
//  Shared
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI

@main
struct ShoppingManiacApp: App {
    let persistenceController:PersistenceController = {
        PersistenceController.previewMode = true
        return PersistenceController.preview
    }()

    var body: some Scene {
        WindowGroup {
            MainScreen()
        }
    }
}
