//
//  AboutModel.swift
//  ShoppingManiac (iOS)
//
//  Created by Dmitry Matyushkin on 10.06.2022.
//

import SwiftUI
import FactoryKit
import Observation

@MainActor
@Observable
final class AboutModel {

    @ObservationIgnored
    @Injected(\.dao) private var dao: DAOProtocol
    @ObservationIgnored
    @Injected(\.shoppingListSerializer) private var serializer: ShoppingListSerializerProtocol
    @ObservationIgnored
    @Injected(\.appEventCenter) private var appEvents
    @ObservationIgnored
    private var backupTask: Task<Void, Never>?
    
    var dataToShare: ExportedList?
    var isLoading: Bool = false
    
    deinit {
        backupTask?.cancel()
    }
    
    func makeBackup() {
        backupTask?.cancel()
        backupTask = Task {
            do {
                isLoading = true
                defer { isLoading = false }
                let lists = try await dao.getShoppingLists()
                guard let firstList = lists.first else {
                    appEvents.showError("Nothing to back up", detail: nil)
                    return
                }
                let backup = try await serializer.exportBackup(lists: lists)
                try Task.checkCancellation()
                dataToShare = ExportedList(id: firstList.id, url: try backup.store(fileExtension: ".smbackup"))
            } catch is CancellationError {
                isLoading = false
            } catch {
                appEvents.showError(error, fallback: "Unable to create backup")
            }
        }
    }
}
