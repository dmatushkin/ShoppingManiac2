//
//  StoresModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import Combine
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
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()
    
    var items: [StoresItemModel] = []
    var showAddSheet: Bool = false
    var searchString: String = "" {
        didSet {
            reload()
        }
    }
    
    init() {
        reload()
        appEvents.dataDidChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.reload()
            }
            .store(in: &cancellables)
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
            _ = try await dao.saveStore(item: item, name: name, categories: categories)
            appEvents.dataChanged()
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
            appEvents.dataChanged()
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
