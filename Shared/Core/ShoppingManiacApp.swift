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
        .register(forType: ShoppingListSerializerProtocol.self, dependency: ShoppingListSerializer.self)

    var body: some Scene {
        WindowGroup {
            MainScreen().onOpenURL { url in
                do {
                    @Autowired(cacheType: .share) var serializer: ShoppingListSerializerProtocol
                    let data = try Data(contentsOf: url)
                    Task {
                        let list = try await serializer.importList(data: data)
                        print("List \(list.title) imported")
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}
