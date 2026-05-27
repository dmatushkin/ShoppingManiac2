//
//  CategoriesModel.swift
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
final class CategoriesModel: EditCategoryModelProtocol {
    
    @ObservationIgnored
    @Injected(\.dao) private var dao: DAOProtocol
    @ObservationIgnored
    @Injected(\.appEventCenter) private var appEvents
    @ObservationIgnored
    private var reloadTask: Task<Void, Never>?
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()
    
    var items: [CategoriesItemModel] = []
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
                let categories = try await dao.getCategories(search: search)
                try Task.checkCancellation()
                items = categories
            } catch is CancellationError {
            } catch {
                appEvents.showError(error, fallback: "Unable to load categories")
            }
        }
    }
        
    func editCategory(item: CategoriesItemModel?, name: String, goods: [String]) async {
        do {
            _ = try await dao.saveCategory(item: item, name: name, goods: goods)
            appEvents.dataChanged()
        } catch {
            appEvents.showError(error, fallback: "Unable to save category")
        }
    }
    
    func removeStore(offsets: IndexSet) async {
        do {
            let itemsToDelete = items.enumerated().filter({ offsets.contains($0.offset) }).map({ $0.element })
            for item in itemsToDelete {
                try await dao.removeCategory(item: item)
            }
            appEvents.dataChanged()
        } catch {
            appEvents.showError(error, fallback: "Unable to delete category")
        }
    }
    
    func getCategoryGoods(category: CategoriesItemModel) async -> [GoodsItemModel] {
        do {
            return try await dao.getCategoryGoods(item: category)
        } catch {
            appEvents.showError(error, fallback: "Unable to load category goods")
        }
        return []
    }
}
