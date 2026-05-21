//
//  GoodsModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import Factory
import Observation

@MainActor
@Observable
final class GoodsModel: EditGoodModelProtocol, Sendable {

    @ObservationIgnored
    @Injected(\.dao) private var dao: DAOProtocol
    @ObservationIgnored
    @Injected(\.appEventCenter) private var appEvents
    @ObservationIgnored
    private var reloadTask: Task<Void, Never>?
    
    var items: [GoodsItemModel] = []
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
                let goods = try await dao.getGoods(search: search)
                try Task.checkCancellation()
                items = goods
            } catch is CancellationError {
            } catch {
                appEvents.showError(error, fallback: "Unable to load goods")
            }
        }
    }
        
    func editGood(item: GoodsItemModel?, name: String, category: String) async {
        do {
            if let item = item {
                _ = try await dao.editGood(item: item, name: name, category: category)
            } else {
                _ = try await dao.addGood(name: name, category: category)
            }
            items = try await dao.getGoods(search: searchString)
        } catch {
            appEvents.showError(error, fallback: "Unable to save good")
        }
    }
    
    func removeGood(offsets: IndexSet) async {
        do {
            let itemsToDelete = items.enumerated().filter({ offsets.contains($0.offset) }).map({ $0.element })
            for item in itemsToDelete {
                try await dao.removeGood(item: item)
            }
            items = try await dao.getGoods(search: searchString)
        } catch {
            appEvents.showError(error, fallback: "Unable to delete good")
        }
    }
}
