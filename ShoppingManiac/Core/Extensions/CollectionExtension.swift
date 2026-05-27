//
//  CollectionExtension.swift
//  ShoppingManiac (iOS)
//
//  Created by Dmitry Matyushkin on 10.06.2022.
//

import Foundation

extension Collection {

    public func asyncCompactMap<ElementOfResult>(_ transform: @escaping @Sendable (Element) async throws -> ElementOfResult?) async rethrows -> [ElementOfResult] where ElementOfResult: Sendable, Element: Sendable {
        return try await withThrowingTaskGroup(of: (Int, ElementOfResult?).self, returning: [ElementOfResult].self, body: { group in
            for (index, item) in self.enumerated() {
                group.addTask {
                    let value = try await transform(item)
                    return (index, value)
                }
            }
            var result = Array<ElementOfResult?>(repeating: nil, count: self.count)
            for try await item in group {
                result[item.0] = item.1
            }
            return result.compactMap { $0 }
        })
    }

    public func asyncMap<ElementOfResult>(_ transform: @escaping @Sendable (Element) async throws -> ElementOfResult) async rethrows -> [ElementOfResult] where ElementOfResult: Sendable, Element: Sendable {
        return try await withThrowingTaskGroup(of: (Int, ElementOfResult).self, returning: [ElementOfResult].self, body: { group in
            for (index, item) in self.enumerated() {
                group.addTask {
                    let value = try await transform(item)
                    return (index, value)
                }
            }
            var result = Array<ElementOfResult?>(repeating: nil, count: self.count)
            for try await item in group {
                result[item.0] = item.1
            }
            return result.map { $0! }
        })
    }
}
