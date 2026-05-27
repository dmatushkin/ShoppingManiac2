import Foundation
import Testing
@testable import ShoppingManiac

@MainActor
struct ShoppingListSerializerTests {
    @Test("Exports a list through DAO-backed JSON")
    func exportList() async throws {
        let dao = StubDAO()
        let list = makeList(id: "list-1", name: "Weekend", date: Date(timeIntervalSince1970: 1_000))
        dao.shoppingListItems = [
            makeShoppingItem(title: "Milk", store: "Market", isPurchased: true, amount: "2", price: "3.5", isImportant: true),
            makeShoppingItem(title: "Bread", store: "", isPurchased: false, amount: "1", price: "1.25", isImportant: false)
        ]

        let data = try await withTestContainer(dao: dao) {
            try await ShoppingListSerializer().exportList(listModel: list)
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = try #require(json?["items"] as? [[String: Any]])

        #expect(json?["name"] as? String == "Weekend")
        #expect(items.count == 2)
        #expect(items.compactMap { $0["good"] as? String }.sorted() == ["Bread", "Milk"])
    }

    @Test("Imports exported list JSON and preserves item fields")
    func importList() async throws {
        let dao = StubDAO()
        let list = makeList(id: "list-1", name: "Weekend", date: Date(timeIntervalSince1970: 1_000))
        dao.shoppingLists = [list]
        dao.shoppingListItems = [
            makeShoppingItem(title: "Milk", store: "Market", isPurchased: true, amount: "2", isWeight: false, price: "3.5", isImportant: true)
        ]

        let data = try await withTestContainer(dao: dao) {
            let serializer = ShoppingListSerializer()
            let data = try await serializer.exportList(listModel: list)
            dao.shoppingLists.removeAll()
            dao.shoppingListItems.removeAll()
            return try await serializer.importList(data: data)
        }

        #expect(data.name == "Weekend")
        #expect(dao.importedShoppingLists.count == 1)
        let importedList = try #require(dao.importedShoppingLists.first)
        #expect(importedList.0 == "Weekend")
        let importedItem = try #require(importedList.2.first)
        #expect(importedItem.name == "Milk")
        #expect(importedItem.store == "Market")
        #expect(importedItem.isImportant)
        #expect(importedItem.isPurchased)
    }

    @Test("Exports and imports backup JSON")
    func backupRoundTrip() async throws {
        let dao = StubDAO()
        let first = makeList(id: "1", name: "First")
        let second = makeList(id: "2", name: "Second")
        dao.shoppingListItems = [makeShoppingItem(title: "Eggs")]

        let imported = try await withTestContainer(dao: dao) {
            let serializer = ShoppingListSerializer()
            let data = try await serializer.exportBackup(lists: [first, second])
            dao.shoppingLists.removeAll()
            dao.shoppingListItems.removeAll()
            return try await serializer.importBackup(data: data)
        }

        #expect(imported.map(\.name) == ["First", "Second"])
        #expect(dao.importedShoppingLists.count == 2)
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

    @Test("Importing an invalid date fails instead of using the current date")
    func importInvalidDateThrows() async throws {
        let data = Data(#"{"version":3,"name":"Weekend","date":"not-a-date","items":[]}"#.utf8)

        do {
            _ = try await withTestContainer(dao: StubDAO()) {
                try await ShoppingListSerializer().importList(data: data)
            }
            Issue.record("Expected invalid date import to throw.")
        } catch let error as ShoppingListSerializer.ImportError {
            #expect(error == .invalidDate("not-a-date"))
        } catch {
            Issue.record("Expected invalidDate, got \(error).")
        }
    }

    @Test("Exporting invalid decimal strings fails instead of writing fallback values")
    func exportInvalidDecimalThrows() async throws {
        let dao = StubDAO()
        dao.shoppingListItems = [makeShoppingItem(title: "Milk", amount: "nope", price: "1")]

        do {
            _ = try await withTestContainer(dao: dao) {
                try await ShoppingListSerializer().exportList(listModel: makeList())
            }
            Issue.record("Expected invalid decimal export to throw.")
        } catch let error as ShoppingListSerializer.ImportError {
            #expect(error == .invalidDecimal("nope"))
        } catch {
            Issue.record("Expected invalidDecimal, got \(error).")
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

    @Test("Importing list propagates transactional import failures")
    func importListPropagatesTransactionalImportFailure() async throws {
        let dao = StubDAO()
        dao.shoppingListItems = [makeShoppingItem(title: "Milk")]
        let data = try await withTestContainer(dao: dao) {
            try await ShoppingListSerializer().exportList(listModel: makeList())
        }
        dao.importShoppingListError = TestFailure.requested("import failed")

        await expectTestFailure(.requested("import failed")) {
            try await withTestContainer(dao: dao) {
                _ = try await ShoppingListSerializer().importList(data: data)
            }
        }
    }

    @Test("Importing backup uses one transactional DAO call")
    func importBackupUsesBatchImport() async throws {
        let dao = StubDAO()
        let backup = Data("""
        {"version":3,"lists":[
          {"version":3,"name":"First","date":"1970-01-01T00:00:00.000Z","items":[]},
          {"version":3,"name":"Second","date":"1970-01-01T00:00:00.000Z","items":[]}
        ]}
        """.utf8)

        _ = try await withTestContainer(dao: dao) {
            try await ShoppingListSerializer().importBackup(data: backup)
        }

        #expect(dao.importedShoppingLists.map(\.0) == ["First", "Second"])
    }

    @Test("Importing backup does not partially import when DAO rejects the batch")
    func importBackupFailureDoesNotPartiallyImport() async throws {
        let dao = StubDAO()
        dao.importShoppingListError = TestFailure.requested("batch failed")
        let backup = Data("""
        {"version":3,"lists":[
          {"version":3,"name":"First","date":"1970-01-01T00:00:00.000Z","items":[]},
          {"version":3,"name":"Second","date":"1970-01-01T00:00:00.000Z","items":[]}
        ]}
        """.utf8)

        await expectTestFailure(.requested("batch failed")) {
            try await withTestContainer(dao: dao) {
                _ = try await ShoppingListSerializer().importBackup(data: backup)
            }
        }
        #expect(dao.importedShoppingLists.isEmpty)
    }
}
