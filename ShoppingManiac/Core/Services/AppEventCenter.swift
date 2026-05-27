//
//  AppEventCenter.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 21.05.2026.
//

import Combine
import Foundation

struct ToastMessage: Identifiable, Equatable {
    enum Style: Equatable {
        case success
        case error
        case info
    }

    let id: UUID
    let style: Style
    let title: String
    let detail: String?

    init(id: UUID = UUID(), style: Style, title: String, detail: String? = nil) {
        self.id = id
        self.style = style
        self.title = title
        self.detail = detail?.nilIfEmpty
    }

    static func success(_ title: String, detail: String? = nil) -> ToastMessage {
        ToastMessage(style: .success, title: title, detail: detail)
    }

    static func error(_ title: String, detail: String? = nil) -> ToastMessage {
        ToastMessage(style: .error, title: title, detail: detail)
    }

    static func info(_ title: String, detail: String? = nil) -> ToastMessage {
        ToastMessage(style: .info, title: title, detail: detail)
    }
}

@MainActor
protocol AppEventCenterProtocol: AnyObject {
    var shoppingListsDidChange: AnyPublisher<Void, Never> { get }
    var dataDidChange: AnyPublisher<Void, Never> { get }
    var toastMessages: AnyPublisher<ToastMessage, Never> { get }

    func shoppingListsChanged()
    func dataChanged()
    func showToast(_ message: ToastMessage)
    func showSuccess(_ title: String, detail: String?)
    func showError(_ title: String, detail: String?)
    func showError(_ error: Error, fallback: String)
}

@MainActor
final class AppEventCenter: AppEventCenterProtocol {
    private let shoppingListsSubject = PassthroughSubject<Void, Never>()
    private let dataSubject = PassthroughSubject<Void, Never>()
    private let toastSubject = PassthroughSubject<ToastMessage, Never>()

    nonisolated init() {}

    var shoppingListsDidChange: AnyPublisher<Void, Never> {
        shoppingListsSubject.eraseToAnyPublisher()
    }

    var dataDidChange: AnyPublisher<Void, Never> {
        dataSubject.eraseToAnyPublisher()
    }

    var toastMessages: AnyPublisher<ToastMessage, Never> {
        toastSubject.eraseToAnyPublisher()
    }

    func shoppingListsChanged() {
        shoppingListsSubject.send()
        dataSubject.send()
    }

    func dataChanged() {
        dataSubject.send()
    }

    func showToast(_ message: ToastMessage) {
        toastSubject.send(message)
    }

    func showSuccess(_ title: String, detail: String? = nil) {
        showToast(.success(title, detail: detail))
    }

    func showError(_ title: String, detail: String? = nil) {
        showToast(.error(title, detail: detail))
    }

    func showError(_ error: Error, fallback: String) {
        let errorDescription = (error as NSError).localizedDescription.nilIfEmpty
        showError(fallback, detail: errorDescription)
    }
}
