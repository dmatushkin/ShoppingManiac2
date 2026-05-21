//
//  StoresModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import FactoryKit
import Observation

@MainActor
@Observable
final class StoresModel: EditStoreModelProtocol {
    
    @ObservationIgnored
    @Injected(\.dao) private var dao: DAOProtocol
    @ObservationIgnored
    @Injected(\.appEventCenter) private var appEvents
    @ObservationIgnored
    private var reloadTask: Task<Void, Never>?
    
    var items: [StoresItemModel] = []
    var showAddSheet: Bool = false
    var searchString: String = "" {
        didSet {
            reload()
        }
    }
    
    init() {
        reload()
    }
    
    deinit {
        reloadTask?.cancel()
    }
    
    func reload() {
        reloadTask?.cancel()
        let search = searchString
        reloadTask = Task {
            do {
                let stores = try await dao.getStores(search: search)
                try Task.checkCancellation()
                items = stores
            } catch is CancellationError {
            } catch {
                appEvents.showError(error, fallback: "Unable to load stores")
            }
        }
    }
        
    func editStore(item: StoresItemModel?, name: String, categories: [String]) async {
        do {
            if let item = item {
                let store = try await dao.editStore(item: item, name: name)
                try await dao.syncStoreCategories(item: store, categories: categories)
            } else {
                let store = try await dao.addStore(name: name)
                try await dao.syncStoreCategories(item: store, categories: categories)
            }
            items = try await dao.getStores(search: searchString)
        } catch {
            appEvents.showError(error, fallback: "Unable to save store")
        }
    }
    
    func removeStore(offsets: IndexSet) async {
        do {
            let itemsToDelete = items.enumerated().filter({ offsets.contains($0.offset) }).map({ $0.element })
            for item in itemsToDelete {
                try await dao.removeStore(item: item)
            }
            items = try await dao.getStores(search: searchString)
        } catch {
            appEvents.showError(error, fallback: "Unable to delete store")
        }
    }
    
    func getStoreCategories(item: StoresItemModel) async -> [CategoriesItemModel] {
        do {
            return try await dao.getStoreCategories(item: item)
        } catch {
            appEvents.showError(error, fallback: "Unable to load store categories")
        }
        return []
    }
}
