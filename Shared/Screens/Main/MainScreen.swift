//
//  MainScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI

struct MainScreen: View {
    
    init() {
        #if os(iOS)
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
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
    }
}

struct MainScreen_Previews: PreviewProvider {
    static var previews: some View {
        MainScreen()
    }
}
