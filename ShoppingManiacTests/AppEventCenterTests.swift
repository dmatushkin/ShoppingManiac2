import Combine
import Testing
@testable import ShoppingManiac

@MainActor
struct AppEventCenterTests {
    @Test("ToastMessage drops empty detail values")
    func toastMessageDropsEmptyDetail() {
        let message = ToastMessage.error("Failed", detail: "")

        #expect(message.detail == nil)
        #expect(message.title == "Failed")
        #expect(message.style == .error)
    }

    @Test("AppEventCenter publishes shopping list changes")
    func publishesShoppingListChanges() {
        let sut = AppEventCenter()
        var changeCount = 0
        var cancellables = Set<AnyCancellable>()
        sut.shoppingListsDidChange
            .sink { changeCount += 1 }
            .store(in: &cancellables)

        sut.shoppingListsChanged()
        sut.shoppingListsChanged()

        #expect(changeCount == 2)
    }

    @Test("AppEventCenter publishes success and error toasts")
    func publishesToasts() throws {
        let sut = AppEventCenter()
        var messages: [ToastMessage] = []
        var cancellables = Set<AnyCancellable>()
        sut.toastMessages
            .sink { messages.append($0) }
            .store(in: &cancellables)

        sut.showSuccess("Saved", detail: "Groceries")
        sut.showError(TestFailure.requested("Disk full"), fallback: "Unable to save")

        #expect(messages.count == 2)
        let success = try #require(messages.first)
        let error = try #require(messages.last)
        #expect(success.style == .success)
        #expect(success.title == "Saved")
        #expect(success.detail == "Groceries")
        #expect(error.style == .error)
        #expect(error.title == "Unable to save")
        #expect(error.detail == "Disk full")
    }
}
