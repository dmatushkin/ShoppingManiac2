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
    @Published var searchString: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task {
            items = try await dao.getCategories(search: "")
        }
        $searchString.sink(receiveValue: {[weak self] value in
            guard let self = self else { return }
            Task {
                self.items = try await self.dao.getCategories(search: value)
            }
        }).store(in: &cancellables)
    }
        
    func editCategory(item: CategoriesItemModel?, name: String) async throws {
        if let item = item {
            _ = try await dao.editCategory(item: item, name: name)
        } else {
            _ = try await dao.addCategory(name: name)
        }        
        items = try await dao.getCategories(search: searchString)
    }
    
    func removeStore(offsets: IndexSet) async throws {
        let itemsToDelete = items.enumerated().filter({ offsets.contains($0.offset) }).map({ $0.element })
        for item in itemsToDelete {
            try await dao.removeCategory(item: item)
        }
        items = try await dao.getCategories(search: searchString)
    }
}
