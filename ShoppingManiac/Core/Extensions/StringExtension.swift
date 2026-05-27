//
//  StringExtension.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10.10.2021.
//

import Foundation

extension String {
    
    nonisolated var nilIfEmpty: String? {
        return self.isEmpty ? nil : self
    }

    nonisolated var shoppingNormalizedName: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated var shoppingCanonicalName: String {
        shoppingNormalizedName
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }
}
