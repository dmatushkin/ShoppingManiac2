//
//  ShoppingManiacUIApp.swift
//  Shared
//
//  Created by Dmitry Matyushkin on 7/4/20.
//

import SwiftUI

@main
struct ShoppingManiacUIApp: App {
	@StateObject private var mainListModel = MainListCoreDataModel() as MainListModel

    var body: some Scene {
        WindowGroup {
			MainListScreen()
				.environmentObject(mainListModel)
        }
    }
}
