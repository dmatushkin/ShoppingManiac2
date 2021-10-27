//
//  CategoriesModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import Combine
import DependencyInjection

@MainActor
final class CategoriesModel: ObservableObject {
    
    @Autowired(cacheType: .share) private var dao: DAOProtocol
    
    @Published var items: [CategoriesItemModel] = []
    @Published var showAddSheet: Bool = false
    
    init() {
        Task {
            items = try await dao.getCategories()
        }
    }
    
    func addCategory(name: String) async throws {
        _ = try await dao.addCategory(name: name)
        items = try await dao.getCategories()
        showAddSheet = false
    }
    
    func editCategory(item: CategoriesItemModel, name: String) async throws {
        _ = try await dao.editCategory(item: item, name: name)
        items = try await dao.getCategories()
    }
    
    func removeStore(offsets: IndexSet) async throws {
        let itemsToDelete = items.enumerated().filter({ offsets.contains($0.offset) }).map({ $0.element })
        for item in itemsToDelete {
            try await dao.removeCategory(item: item)
        }
        items = try await dao.getCategories()
    }
}
