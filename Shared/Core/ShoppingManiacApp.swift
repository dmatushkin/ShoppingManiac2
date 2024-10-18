//
//  ShoppingManiac2App.swift
//  Shared
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI
@preconcurrency import Combine
import Factory

final class GlobalCommands {
    
    static let reloadTopList = PassthroughSubject<Void, Never>()
}

@main
struct ShoppingManiacApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            MainScreen().onOpenURL { url in
                do {
                    let data = try Data(contentsOf: url)
                    Task {
                        do {
                            if url.pathExtension == "smstorage" {
                                let list = try await Container.shared.shoppingListSerializer().importList(data: data)
                                print("List \(list.title) imported")
                                GlobalCommands.reloadTopList.send()
                            } else if url.pathExtension == "smbackup" {
                                let backup = try await Container.shared.shoppingListSerializer().importBackup(data: data)
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
