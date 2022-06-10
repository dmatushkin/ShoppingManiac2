//
//  CollectionExtension.swift
//  ShoppingManiac (iOS)
//
//  Created by Dmitry Matyushkin on 10.06.2022.
//

import Foundation

extension Collection {

    public func asyncCompactMap<ElementOfResult>(_ transform: @escaping (Element) async throws -> ElementOfResult?) async rethrows -> [ElementOfResult] {
        return try await withThrowingTaskGroup(of: ElementOfResult?.self, returning: [ElementOfResult].self, body: { group in
            var result: [ElementOfResult] = []
            result.reserveCapacity(self.count)
            for item in self {
                group.addTask {
                    try await transform(item)
                }
            }
            for try await item in group {
                if let item = item {
                    result.append(item)
                }
            }
            return result
        })
    }

    public func asyncMap<ElementOfResult>(_ transform: @escaping (Element) async throws -> ElementOfResult) async rethrows -> [ElementOfResult] {
        return try await withThrowingTaskGroup(of: ElementOfResult.self, returning: [ElementOfResult].self, body: { group in
            var result: [ElementOfResult] = []
            result.reserveCapacity(self.count)
            for item in self {
                group.addTask {
                    try await transform(item)
                }
            }
            for try await item in group {
                result.append(item)
            }
            return result
        })
    }
}
