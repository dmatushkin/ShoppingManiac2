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
    
    private func reloadCategories() {
        Task {
            categoryNames = try await dao.getCategories(search: itemName).map({ $0.name })
        }
    }
}
