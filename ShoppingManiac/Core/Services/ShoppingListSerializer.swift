//
//  ShoppingListExporter.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 25.01.2022.
//

import Foundation
import FactoryKit

protocol ShoppingListSerializerProtocol: Sendable {
    func exportList(listModel: ShoppingListModel) async throws -> Data
    func importList(data: Data) async throws -> ShoppingListModel
    func exportBackup(lists: [ShoppingListModel]) async throws -> Data
    func importBackup(data: Data) async throws -> [ShoppingListModel]
}

final class ShoppingListSerializer: ShoppingListSerializerProtocol, @unchecked Sendable {

    nonisolated required init() {}
    
    @Injected(\.dao) private var dao: DAOProtocol
    
    private struct Backup: Codable {
        static let currentVersion = 3

        let version: Int?
        let lists: [ShoppingListJsonModel]

        init(lists: [ShoppingListJsonModel]) {
            self.version = Self.currentVersion
            self.lists = lists
        }
    }
    
    private struct ShoppingListJsonModel: Codable {
        static let currentVersion = 3

        let version: Int?
        let name: String
        let date: String
        let items: [ShoppingListItemJsonModel]

        init(name: String, date: String, items: [ShoppingListItemJsonModel]) {
            self.version = Self.currentVersion
            self.name = name
            self.date = date
            self.items = items
        }
    }
    
    private struct ShoppingListItemJsonModel: Codable {
        let good: String
        let store: String
        let price: Decimal
        let purchased: Bool
        let quantity: Decimal
        let isWeight: Bool
        let isImportant: Bool
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private static func exportedDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private static func importedDate(_ string: String) -> Date {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: string) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) {
            return date
        }

        let legacyFormatter = DateFormatter()
        legacyFormatter.dateStyle = .medium
        legacyFormatter.timeStyle = .medium
        return legacyFormatter.date(from: string) ?? Date()
    }

    private static func decimal(from string: String, default defaultValue: Decimal) -> Decimal {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let decimal = Decimal(string: trimmed, locale: Locale.current) {
            return decimal
        }
        if let decimal = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")) {
            return decimal
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.number(from: trimmed)?.decimalValue ?? defaultValue
    }
    
    private func listModelToJson(listModel: ShoppingListModel) async throws -> ShoppingListJsonModel {
        let listItems = try await dao.getShoppingListItems(list: listModel)
        
        let items: [ShoppingListItemJsonModel] = listItems.map({
            ShoppingListItemJsonModel(good: $0.title,
                                      store: $0.store,
                                      price: Self.decimal(from: $0.price, default: 0),
                                      purchased: $0.isPurchased,
                                      quantity: Self.decimal(from: $0.amount, default: 1),
                                      isWeight: $0.isWeight,
                                      isImportant: $0.isImportant)
        })
        return ShoppingListJsonModel(name: listModel.name, date: Self.exportedDate(listModel.date), items: items)
    }
    
    private func jsonToListModel(jsonModel: ShoppingListJsonModel) async throws -> ShoppingListModel {
        let items = jsonModel.items.map {
            ShoppingListImportItem(
                name: $0.good,
                amount: $0.quantity,
                store: $0.store,
                isWeight: $0.isWeight,
                price: $0.price,
                isImportant: $0.isImportant,
                isPurchased: $0.purchased
            )
        }
        return try await dao.importShoppingList(
            name: jsonModel.name,
            date: Self.importedDate(jsonModel.date),
            items: items
        )
    }
    
    func exportList(listModel: ShoppingListModel) async throws -> Data {
        let listJsonModel = try await listModelToJson(listModel: listModel)
        return try Self.makeEncoder().encode(listJsonModel)
    }
    
    func importList(data: Data) async throws -> ShoppingListModel {
        let jsonModel = try JSONDecoder().decode(ShoppingListJsonModel.self, from: data)
        return try await jsonToListModel(jsonModel: jsonModel)
    }
    
    func exportBackup(lists: [ShoppingListModel]) async throws -> Data {
        var jsonList: [ShoppingListJsonModel] = []
        jsonList.reserveCapacity(lists.count)
        for model in lists {
            jsonList.append(try await listModelToJson(listModel: model))
        }
        let backup = Backup(lists: jsonList)
        return try Self.makeEncoder().encode(backup)
    }
    
    func importBackup(data: Data) async throws -> [ShoppingListModel] {
        let backup = try JSONDecoder().decode(Backup.self, from: data)
        var lists: [ShoppingListModel] = []
        lists.reserveCapacity(backup.lists.count)
        for list in backup.lists {
            lists.append(try await jsonToListModel(jsonModel: list))
        }
        return lists
    }
}
