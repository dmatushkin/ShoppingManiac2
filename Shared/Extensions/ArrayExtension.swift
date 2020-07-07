//
//  ArrayExtension.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 7/8/20.
//

import Foundation

extension Array {

	subscript(indexSet: IndexSet) -> Self {
		return enumerated().filter({ indexSet.contains( $0.offset)}).map({$0.element})
	}
}
