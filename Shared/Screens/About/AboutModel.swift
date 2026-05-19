//
//  AboutModel.swift
//  ShoppingManiac (iOS)
//
//  Created by Dmitry Matyushkin on 10.06.2022.
//

import SwiftUI
import Factory
import Observation

@MainActor
@Observable
final class AboutModel {

    @ObservationIgnored
    @Injected(\.dao) private var dao: DAOProtocol
    @ObservationIgnored
    @Injected(\.shoppingListSerializer) private var serializer: ShoppingListSerializerProtocol
    
    var dataToShare: ExportedList?
    
    func makeBackup() {
        Task {
            let lists = try await dao.getShoppingLists()
            guard lists.count > 0 else { return }
            let backup = try await serializer.exportBackup(lists: lists)
            dataToShare = ExportedList(id: lists[0].id, url: try backup.store(fileExtension: ".smbackup"))
        }
    }
}
