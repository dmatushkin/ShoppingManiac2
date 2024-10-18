//
//  ShoppingManiac2App.swift
//  Shared
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI
import DependencyInjection
@preconcurrency import Combine

final class GlobalCommands {
    
    static let reloadTopList = PassthroughSubject<Void, Never>()
}

@main
struct ShoppingManiacApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
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
                        do {
                            if url.pathExtension == "smstorage" {
                                let list = try await serializer.importList(data: data)
                                print("List \(list.title) imported")
                                GlobalCommands.reloadTopList.send()
                            } else if url.pathExtension == "smbackup" {
                                let backup = try await serializer.importBackup(data: data)
                                print("Backup of \(backup.count) imported")
                                GlobalCommands.reloadTopList.send()
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}
