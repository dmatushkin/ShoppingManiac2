//
//  AddCategoryToStoreModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 21.01.2022.
//

import Foundation
import Factory
import Observation

@MainActor
@Observable
final class AddCategoryToStoreModel {
    
    var categoryNames: [String] = []
    var itemName: String = "" {
        didSet {
            reloadCategories()
        }
    }
    @ObservationIgnored
    @Injected(\.dao) private var dao: DAOProtocol
    @ObservationIgnored
    private var reloadTask: Task<Void, Never>?
    
    deinit {
        reloadTask?.cancel()
    }
    
    private func reloadCategories() {
        reloadTask?.cancel()
        let search = itemName
        reloadTask = Task {
            do {
                let names = try await dao.getCategories(search: search).map({ $0.name })
                try Task.checkCancellation()
                categoryNames = names
            } catch is CancellationError {
            } catch {
            }
        }
    }
}
