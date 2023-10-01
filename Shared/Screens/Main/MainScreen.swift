//
//  MainScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI
import DependencyInjection

struct MainScreen: View {
    
    @StateObject private var model: MainScreenModel
    
    init() {
        #if os(iOS)
        UITableView.appearance().backgroundColor = .clear
        #endif
        _model = StateObject(wrappedValue: MainScreenModel())
    }
    
    var body: some View {
        ZStack {
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
            LoadingView().opacity(model.isLoaded ? 0 : 0.9)
        }.scrollContentBackground(.hidden)
    }
}

struct MainScreen_Previews: PreviewProvider {
    static var previews: some View {
        DIProvider.shared
            .register(forType: DAOProtocol.self, dependency: DAOStub.self)
            .showView(MainScreen())
        
    }
}
