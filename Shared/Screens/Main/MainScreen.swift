//
//  MainScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI

struct MainScreen: View {
    var body: some View {
        TabView {
            ShoppingScreen().tabItem {
                Image(systemName: "list.bullet")
                Text("Shopping")
            }
            GoodsScreen().tabItem {
                Image(systemName: "square.grid.3x2")
                Text("Goods")
            }
            StoresScreen().tabItem {
                Image(systemName: "house")
                Text("Stores")
            }
            CategoriesScreen().tabItem {
                Image(systemName: "rectangle.3.offgrid")
                Text("Categories")
            }
            AboutScreen().tabItem {
                Image(systemName: "cart")
                Text("About")
            }
        }
    }
}

struct MainScreen_Previews: PreviewProvider {
    static var previews: some View {
        MainScreen().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
