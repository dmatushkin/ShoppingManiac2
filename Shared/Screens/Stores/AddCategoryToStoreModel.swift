//
//  AddCategoryToStoreModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 21.01.2022.
//

import Foundation
import Combine
import DependencyInjection

@MainActor
final class AddCategoryToStoreModel: ObservableObject {
    
    @Published var categoryNames: [String] = []
    @Published var itemName: String = ""
    private var cancellables = Set<AnyCancellable>()
    @Autowired(cacheType: .share) private var dao: DAOProtocol
    
    init() {
        $itemName.sink(receiveValue: {value in
            Task { [weak self] in
                self?.categoryNames = try await self?.dao.getCategories(search: value).map({ $0.name }) ?? []
            }
        }).store(in: &cancellables)
    }
}
