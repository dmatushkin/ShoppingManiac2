//
//  ShoppingManiac2App.swift
//  Shared
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI
import Factory

@main
struct ShoppingManiacApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    var body: some Scene {
        WindowGroup {
            MainScreen().onOpenURL { url in
                handleOpenURL(url)
            }
        }
    }

    @MainActor
    private func handleOpenURL(_ url: URL) {
        Task { @MainActor in
            let events = Container.shared.appEventCenter()
            do {
                let data = try Data(contentsOf: url)

                switch url.pathExtension.lowercased() {
                case "smstorage":
                    let list = try await Container.shared.shoppingListSerializer().importList(data: data)
                    events.shoppingListsChanged()
                    events.showSuccess("Shopping list imported", detail: list.title)
                case "smbackup":
                    let backup = try await Container.shared.shoppingListSerializer().importBackup(data: data)
                    events.shoppingListsChanged()
                    events.showSuccess("Backup imported", detail: "\(backup.count) lists restored")
                default:
                    events.showError("Unsupported file", detail: url.lastPathComponent)
                }
            } catch {
                events.showError(error, fallback: "Unable to import file")
            }
        }
    }
}
