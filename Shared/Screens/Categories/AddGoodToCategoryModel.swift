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
    @ObservationIgnored
    private var reloadTask: Task<Void, Never>?
    
    deinit {
        reloadTask?.cancel()
    }
    
    private func reloadGoods() {
        reloadTask?.cancel()
        let search = itemName
        reloadTask = Task {
            do {
                let names = try await dao.getGoods(search: search).map({ $0.name })
                try Task.checkCancellation()
                goodsNames = names
            } catch is CancellationError {
            } catch {
            }
        }
    }
}
