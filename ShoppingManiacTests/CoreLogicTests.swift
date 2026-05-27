import Foundation
import Testing
@testable import ShoppingManiac

@MainActor
struct CoreLogicTests {
    @Test("String.nilIfEmpty returns nil only for the empty string")
    func nilIfEmpty() {
        #expect("".nilIfEmpty == nil)
        #expect(" ".nilIfEmpty == " ")
        #expect("Milk".nilIfEmpty == "Milk")
    }

    @Test("ShoppingListModel title prefers non-empty name")
    func shoppingListTitleUsesName() {
        let date = Date(timeIntervalSince1970: 0)
        let list = ShoppingListModel(id: "1", name: "Weekend", date: date)

        #expect(list.title == "Weekend")
    }

    @Test("ShoppingListModel title falls back to formatted date")
    func shoppingListTitleUsesDateWhenNameIsEmpty() {
        let date = Date(timeIntervalSince1970: 0)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let list = ShoppingListModel(id: "1", name: "", date: date)

        #expect(list.title == formatter.string(from: date))
    }

    @Test("Optional NSSet converts to typed arrays")
    func optionalNSSetConversion() {
        let values: NSSet? = NSSet(array: ["Milk", "Bread"])
        let strings: [String] = values.getArray()
        let nilSet: NSSet? = nil
        let empty: [String] = nilSet.getArray()
        let wrongType: [Int] = values.getArray()

        #expect(Set(strings) == Set(["Milk", "Bread"]))
        #expect(empty.isEmpty)
        #expect(wrongType.isEmpty)
    }

    @Test("asyncMap maps every element")
    func asyncMapMapsEveryElement() async throws {
        let result = await [1, 2, 3].asyncMap { value in
            value * 2
        }

        #expect(result.sorted() == [2, 4, 6])
    }

    @Test("asyncCompactMap removes nil values")
    func asyncCompactMapRemovesNilValues() async throws {
        let result: [Int] = await [1, 2, 3, 4].asyncCompactMap { value in
            value.isMultiple(of: 2) ? value : nil
        }

        #expect(result.sorted() == [2, 4])
    }

    @Test("asyncMap propagates thrown errors")
    func asyncMapPropagatesErrors() async {
        await expectTestFailure(.requested("map failed")) {
            _ = try await [1, 2, 3].asyncMap { value in
                if value == 2 {
                    throw TestFailure.requested("map failed")
                }
                return value
            }
        }
    }

    @Test("asyncCompactMap propagates thrown errors")
    func asyncCompactMapPropagatesErrors() async {
        await expectTestFailure(.requested("compact failed")) {
            _ = try await [1, 2, 3].asyncCompactMap { value -> Int? in
                if value == 3 {
                    throw TestFailure.requested("compact failed")
                }
                return value
            }
        }
    }

    @Test("Data.store writes file and removes prior files with the same extension")
    func dataStoreWritesAndReplacesFiles() throws {
        let fileExtension = ".shoppingmaniac-test-\(UUID().uuidString)"
        let firstURL = try Data("first".utf8).store(fileExtension: fileExtension)
        defer { try? FileManager.default.removeItem(at: firstURL) }

        #expect(FileManager.default.fileExists(atPath: firstURL.path))

        let secondURL = try Data("second".utf8).store(fileExtension: fileExtension)
        defer { try? FileManager.default.removeItem(at: secondURL) }
        let storedData = try Data(contentsOf: secondURL)

        #expect(FileManager.default.fileExists(atPath: firstURL.path) == false)
        #expect(storedData == Data("second".utf8))
    }
}
