//
//  PreviewModeEnvironment.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 7/31/20.
//

import SwiftUI

struct PreviewModeEnvironmentKey: EnvironmentKey {
	static let defaultValue: Bool = true
}

extension EnvironmentValues {
	var previewMode: Bool {
		get {
			return self[PreviewModeEnvironmentKey]
		}
		set {
			self[PreviewModeEnvironmentKey] = newValue
		}
	}
}
