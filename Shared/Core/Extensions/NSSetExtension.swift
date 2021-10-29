//
//  NSSetExtension.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 09.10.2021.
//

import Foundation
import SwiftUI

extension Optional where Wrapped == NSSet {
    
    func getArray<T>() -> [T] {
        return (Array(self ?? []) as? [T]) ?? []
    }
}
