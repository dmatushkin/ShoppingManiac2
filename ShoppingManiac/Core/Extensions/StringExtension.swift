//
//  StringExtension.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 10.10.2021.
//

import Foundation

extension String {
    
    var nilIfEmpty: String? {
        return self.isEmpty ? nil : self
    }
}
