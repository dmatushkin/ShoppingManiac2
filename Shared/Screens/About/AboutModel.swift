//
//  AboutModel.swift
//  ShoppingManiac (iOS)
//
//  Created by Dmitry Matyushkin on 10.06.2022.
//

import SwiftUI
import Factory

@MainActor
final class AboutModel: ObservableObject {

    @Injected(\.dao) private var dao: DAOProtocol
    @Injected(\.shoppingListSerializer) private var serializer: ShoppingListSerializerProtocol
    
    @Published var dataToShare: ExportedList?
    
    func makeBackup() {
        Task {
            let lists = try await dao.getShoppingLists()
            guard lists.count > 0 else { return }
            let backup = try await serializer.exportBackup(lists: lists)
            dataToShare = ExportedList(id: lists[0].id, url: try backup.store(fileExtension: ".smbackup"))
        }
    }
}
