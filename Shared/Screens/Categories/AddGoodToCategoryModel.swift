//
//  AddGoodToCategoryModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 21.01.2022.
//

import Foundation
import Factory
import Observation

@MainActor
@Observable
final class AddGoodToCategoryModel {
    
    var goodsNames: [String] = []
    var itemName: String = "" {
        didSet {
            reloadGoods()
        }
    }
    @ObservationIgnored
    @Injected(\.dao) private var dao: DAOProtocol
    
    private func reloadGoods() {
        Task {
            goodsNames = try await dao.getGoods(search: itemName).map({ $0.name })
        }
    }
}
