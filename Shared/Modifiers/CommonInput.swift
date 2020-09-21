//
//  CommonInput.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 9/21/20.
//

import SwiftUI

struct CommonInput: ViewModifier {

	func body(content: Content) -> some View {
		return content.padding().overlay(
			RoundedRectangle(cornerRadius: 5).stroke(Color.black, lineWidth: 1)
		)
	}
}

extension View {
	func commonInput() -> some View {
		return self.modifier(CommonInput())
	}
}
