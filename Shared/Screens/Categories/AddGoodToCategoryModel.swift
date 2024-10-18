//
//  AddGoodToCategoryModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 21.01.2022.
//

import Foundation
import Combine
import Factory

@MainActor
final class AddGoodToCategoryModel: ObservableObject {
    
    @Published var goodsNames: [String] = []
    @Published var itemName: String = ""
    private var cancellables = Set<AnyCancellable>()
    @Injected(\.dao) private var dao: DAOProtocol
    
    init() {
        $itemName.sink(receiveValue: {value in
            Task { [weak self] in
                self?.goodsNames = try await self?.dao.getGoods(search: value).map({ $0.name }) ?? []
            }
        }).store(in: &cancellables)
    }
}
