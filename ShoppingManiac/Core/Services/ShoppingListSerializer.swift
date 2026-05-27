//
//  ShoppingListExporter.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 25.01.2022.
//

import Foundation
import FactoryKit

@MainActor
protocol ShoppingListSerializerProtocol {
    func exportList(listModel: ShoppingListModel) async throws -> Data
    func importList(data: Data) async throws -> ShoppingListModel
    func exportBackup(lists: [ShoppingListModel]) async throws -> Data
    func importBackup(data: Data) async throws -> [ShoppingListModel]
}

@MainActor
final class ShoppingListSerializer: ShoppingListSerializerProtocol {
    enum ImportError: Error, Equatable, LocalizedError {
        case invalidDate(String)
        case invalidDecimal(String)
        case unsupportedListVersion(Int)
        case unsupportedBackupVersion(Int)

        var errorDescription: String? {
            switch self {
            case .invalidDate(let value):
                "Invalid shopping list date: \(value)"
            case .invalidDecimal(let value):
                "Invalid decimal value: \(value)"
            case .unsupportedListVersion(let version):
                "Unsupported shopping list file version: \(version)"
            case .unsupportedBackupVersion(let version):
                "Unsupported backup file version: \(version)"
            }
        }
    }

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

    private static func importedDate(_ string: String) throws -> Date {
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
        if let date = legacyFormatter.date(from: string) {
            return date
        }

        throw ImportError.invalidDate(string)
    }

    private static func decimal(from string: String) throws -> Decimal {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let decimal = Decimal(string: trimmed, locale: Locale.current) {
            return decimal
        }
        if let decimal = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")) {
            return decimal
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if let decimal = formatter.number(from: trimmed)?.decimalValue {
            return decimal
        }

        throw ImportError.invalidDecimal(string)
    }

    private static func validateListVersion(_ version: Int?) throws {
        guard let version else { return }
        guard version <= ShoppingListJsonModel.currentVersion else {
            throw ImportError.unsupportedListVersion(version)
        }
    }

    private static func validateBackupVersion(_ version: Int?) throws {
        guard let version else { return }
        guard version <= Backup.currentVersion else {
            throw ImportError.unsupportedBackupVersion(version)
        }
    }
    
    private func listModelToJson(listModel: ShoppingListModel) async throws -> ShoppingListJsonModel {
        let listItems = try await dao.getShoppingListItems(list: listModel)
        
        let items: [ShoppingListItemJsonModel] = try listItems.map({
            try ShoppingListItemJsonModel(good: $0.title,
                                          store: $0.store,
                                          price: Self.decimal(from: $0.price),
                                          purchased: $0.isPurchased,
                                          quantity: Self.decimal(from: $0.amount),
                                          isWeight: $0.isWeight,
                                          isImportant: $0.isImportant)
        })
        return ShoppingListJsonModel(name: listModel.name, date: Self.exportedDate(listModel.date), items: items)
    }
    
    private static func shoppingListImport(from jsonModel: ShoppingListJsonModel) throws -> ShoppingListImport {
        try validateListVersion(jsonModel.version)
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
        return ShoppingListImport(
            name: jsonModel.name,
            date: try importedDate(jsonModel.date),
            items: items
        )
    }
    
    func exportList(listModel: ShoppingListModel) async throws -> Data {
        let listJsonModel = try await listModelToJson(listModel: listModel)
        return try Self.makeEncoder().encode(listJsonModel)
    }
    
    func importList(data: Data) async throws -> ShoppingListModel {
        let jsonModel = try JSONDecoder().decode(ShoppingListJsonModel.self, from: data)
        let importModel = try Self.shoppingListImport(from: jsonModel)
        return try await dao.importShoppingList(
            name: importModel.name,
            date: importModel.date,
            items: importModel.items
        )
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
        try Self.validateBackupVersion(backup.version)
        let imports = try backup.lists.map(Self.shoppingListImport)
        return try await dao.importShoppingLists(imports)
    }
}
