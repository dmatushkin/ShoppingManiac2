//
//  ShoppingListExporter.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 25.01.2022.
//

import Foundation
import DependencyInjection
import CoreData

protocol ShoppingListSerializerProtocol {
    func exportList(listModel: ShoppingListModel) async throws -> Data
    func importList(data: Data) async throws -> ShoppingListModel
}

final class ShoppingListSerializer: ShoppingListSerializerProtocol, DIDependency {
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.medium
        return dateFormatter
    }()
    
    private let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()
    
    required init() {}
    
    @Autowired(cacheType: .share) private var dao: DAOProtocol
    
    private struct ShoppingListJsonModel: Codable {
        let name: String
        let date: String
        let uniqueId: String?
        let items: [ShoppingListItemJsonModel]
    }
    
    private struct ShoppingListItemJsonModel: Codable {
        let good: String
        let store: String
        let price: Decimal
        let purchased: Bool
        let quantity: Decimal
        let isWeight: Bool
        let isImportant: Bool
        let uniqueId: String?
    }
    
    func exportList(listModel: ShoppingListModel) async throws -> Data {
        let listItems = try await dao.getShoppingListItems(list: listModel)
        
        let items: [ShoppingListItemJsonModel] = listItems.map({
            ShoppingListItemJsonModel(good: $0.title,
                                      store: $0.store,
                                      price: numberFormatter.number(from: $0.price)?.decimalValue ?? 0,
                                      purchased: $0.isPurchased,
                                      quantity: numberFormatter.number(from: $0.amount)?.decimalValue ?? 1,
                                      isWeight: $0.isWeight,
                                      isImportant: $0.isImportant,
                                      uniqueId: $0.uniqueId)
        })
        let listJsonModel = ShoppingListJsonModel(name: listModel.name, date: dateFormatter.string(from: listModel.date), uniqueId: listModel.uniqueId, items: items)        
        return try JSONEncoder().encode(listJsonModel)
    }
    
    func importList(data: Data) async throws -> ShoppingListModel {
        let jsonModel = try JSONDecoder().decode(ShoppingListJsonModel.self, from: data)
        let list = try await dao.addShoppingList(name: jsonModel.name, date: dateFormatter.date(from: jsonModel.date) ?? Date(), uniqueId: jsonModel.uniqueId)
        for item in jsonModel.items {
            try await dao.addShoppingListItem(list: list,
                                              name: item.good,
                                              amount: numberFormatter.string(from: item.quantity as NSNumber) ?? "",
                                              store: item.store,
                                              isWeight: item.isWeight,
                                              price: numberFormatter.string(from: item.price as NSNumber) ?? "",
                                              isImportant: item.isImportant,
                                              rating: 0,
                                              isPurchased: item.purchased,
                                              uniqueId: item.uniqueId)
        }
        return list
    }
}
