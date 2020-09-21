//
//  CommonButton.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 9/21/20.
//

import SwiftUI

struct CommonButton: ViewModifier {
	let isSuccess: Bool
	func body(content: Content) -> some View {
		return content
			.foregroundColor(Color.white)
			.frame(idealWidth: .infinity, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: 50, idealHeight: 50, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
			.background(isSuccess ? Color.green : Color.red)
			.cornerRadius(5)
	}
}

extension View {
	func commonButton(success: Bool) -> some View {
		return self.modifier(CommonButton(isSuccess: success))
	}
}
