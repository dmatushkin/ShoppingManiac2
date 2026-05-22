import Foundation
import Testing
@testable import ShoppingManiac

@MainActor
struct ShoppingListSerializerTests {
    @Test("Exports a list through DAO-backed JSON")
    func exportList() async throws {
        let dao = StubDAO()
        let list = makeList(id: "list-1", uniqueId: "unique-list", name: "Weekend", date: Date(timeIntervalSince1970: 1_000))
        dao.shoppingListItems = [
            makeShoppingItem(uniqueId: "item-1", title: "Milk", store: "Market", isPurchased: true, amount: "2", price: "3.5", isImportant: true),
            makeShoppingItem(uniqueId: "item-2", title: "Bread", store: "", isPurchased: false, amount: "1", price: "1.25", isImportant: false)
        ]

        let data = try await withTestContainer(dao: dao) {
            try await ShoppingListSerializer().exportList(listModel: list)
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = try #require(json?["items"] as? [[String: Any]])

        #expect(json?["name"] as? String == "Weekend")
        #expect(json?["uniqueId"] as? String == "unique-list")
        #expect(items.count == 2)
        #expect(items.compactMap { $0["good"] as? String }.sorted() == ["Bread", "Milk"])
    }

    @Test("Imports exported list JSON and preserves item fields")
    func importList() async throws {
        let dao = StubDAO()
        let list = makeList(id: "list-1", uniqueId: "unique-list", name: "Weekend", date: Date(timeIntervalSince1970: 1_000))
        dao.shoppingLists = [list]
        dao.shoppingListItems = [
            makeShoppingItem(uniqueId: "item-1", title: "Milk", store: "Market", isPurchased: true, amount: "2", isWeight: false, price: "3.5", isImportant: true)
        ]

        let data = try await withTestContainer(dao: dao) {
            let serializer = ShoppingListSerializer()
            let data = try await serializer.exportList(listModel: list)
            dao.shoppingLists.removeAll()
            dao.shoppingListItems.removeAll()
            return try await serializer.importList(data: data)
        }

        #expect(data.name == "Weekend")
        #expect(data.uniqueId == "unique-list")
        #expect(dao.addedShoppingListItems.count == 1)
        let importedItem = try #require(dao.addedShoppingListItems.first)
        #expect(importedItem.1 == "Milk")
        #expect(importedItem.3 == "Market")
        #expect(importedItem.6)
        #expect(importedItem.8)
        #expect(importedItem.9 == "item-1")
    }

    @Test("Exports and imports backup JSON")
    func backupRoundTrip() async throws {
        let dao = StubDAO()
        let first = makeList(id: "1", uniqueId: "u1", name: "First")
        let second = makeList(id: "2", uniqueId: "u2", name: "Second")
        dao.shoppingListItems = [makeShoppingItem(uniqueId: "item-1", title: "Eggs")]

        let imported = try await withTestContainer(dao: dao) {
            let serializer = ShoppingListSerializer()
            let data = try await serializer.exportBackup(lists: [first, second])
            dao.shoppingLists.removeAll()
            dao.shoppingListItems.removeAll()
            return try await serializer.importBackup(data: data)
        }

        #expect(imported.map(\.name) == ["First", "Second"])
        #expect(dao.addedShoppingListItems.count == 2)
    }

    @Test("Importing malformed list JSON throws a decoding error")
    func importMalformedListThrows() async throws {
        let data = Data(#"{"name":"Weekend","date":42,"items":[]}"#.utf8)

        do {
            _ = try await withTestContainer(dao: StubDAO()) {
                try await ShoppingListSerializer().importList(data: data)
            }
            Issue.record("Expected malformed list JSON to throw.")
        } catch is DecodingError {
        } catch {
            Issue.record("Expected DecodingError, got \(error).")
        }
    }

    @Test("Importing malformed backup JSON throws a decoding error")
    func importMalformedBackupThrows() async throws {
        let data = Data(#"{"lists":42}"#.utf8)

        do {
            _ = try await withTestContainer(dao: StubDAO()) {
                try await ShoppingListSerializer().importBackup(data: data)
            }
            Issue.record("Expected malformed backup JSON to throw.")
        } catch is DecodingError {
        } catch {
            Issue.record("Expected DecodingError, got \(error).")
        }
    }

    @Test("Exporting list propagates DAO load failures")
    func exportListPropagatesDAOFailure() async {
        let dao = StubDAO()
        dao.getShoppingListItemsError = TestFailure.requested("items failed")

        await expectTestFailure(.requested("items failed")) {
            try await withTestContainer(dao: dao) {
                _ = try await ShoppingListSerializer().exportList(listModel: makeList())
            }
        }
    }

    @Test("Importing list propagates add-list failures")
    func importListPropagatesAddListFailure() async throws {
        let dao = StubDAO()
        dao.shoppingListItems = [makeShoppingItem(title: "Milk")]
        let data = try await withTestContainer(dao: dao) {
            try await ShoppingListSerializer().exportList(listModel: makeList())
        }
        dao.addShoppingListError = TestFailure.requested("add list failed")

        await expectTestFailure(.requested("add list failed")) {
            try await withTestContainer(dao: dao) {
                _ = try await ShoppingListSerializer().importList(data: data)
            }
        }
    }

    @Test("Importing list propagates add-item failures")
    func importListPropagatesAddItemFailure() async throws {
        let dao = StubDAO()
        dao.shoppingListItems = [makeShoppingItem(title: "Milk")]
        let data = try await withTestContainer(dao: dao) {
            try await ShoppingListSerializer().exportList(listModel: makeList())
        }
        dao.addShoppingListItemError = TestFailure.requested("add item failed")

        await expectTestFailure(.requested("add item failed")) {
            try await withTestContainer(dao: dao) {
                _ = try await ShoppingListSerializer().importList(data: data)
            }
        }
    }
}
