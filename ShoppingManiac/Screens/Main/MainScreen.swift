//
//  MainScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI
import FactoryKit

struct MainScreen: View {
    init() {
        #if os(iOS)
        UITableView.appearance().backgroundColor = .clear
        #endif
    }
    
    var body: some View {
        TabView {
            ShoppingScreen().tabItem {
                Image("documents")
                Text("Shopping")
            }
            GoodsScreen().tabItem {
                Image("goods")
                Text("Goods")
            }
            StoresScreen().tabItem {
                Image("store")
                Text("Stores")
            }
            CategoriesScreen().tabItem {
                Image("categories")
                Text("Categories")
            }
            AboutScreen().tabItem {
                Image("empty_cart")
                Text("About")
            }
        }
        .scrollContentBackground(.hidden)
        .toastOverlay()
    }
}

#Preview {
    let _ = Container.shared.dao.register(factory: { DAOStub() })
    MainScreen()
}
