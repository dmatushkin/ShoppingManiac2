//
//  ShoppingManiac2App.swift
//  Shared
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI
import DependencyInjection

@main
struct ShoppingManiacApp: App {
    
    private let diProvider = DIProvider.shared
        .register(forType: ContextProviderProtocol.self, dependency: ContextProvider.self)
        .register(forType: DAOProtocol.self, dependency: DAO.self)

    var body: some Scene {
        WindowGroup {
            MainScreen()
        }
    }
}
