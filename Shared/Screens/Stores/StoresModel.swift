//
//  StoresModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import Combine
import DependencyInjection

@MainActor
final class StoresModel: ObservableObject {
    
    @Autowired(cacheType: .share) private var dao: DAOProtocol
    
    @Published var items: [StoresItemModel] = []
    @Published var showAddSheet: Bool = false
    
    init() {
        Task {
            items = try await dao.getStores()
        }
    }
        
    func editStore(item: StoresItemModel?, name: String) async throws {
        if let item = item {
            _ = try await dao.editStore(item: item, name: name)
        } else {
            _ = try await dao.addStore(name: name)
        }        
        items = try await dao.getStores()
    }
    
    func removeStore(offsets: IndexSet) async throws {
        let itemsToDelete = items.enumerated().filter({ offsets.contains($0.offset) }).map({ $0.element })
        for item in itemsToDelete {
            try await dao.removeStore(item: item)
        }
        items = try await dao.getStores()
    }
}
