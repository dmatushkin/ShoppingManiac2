//
//  ShoppingScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI
import CoreData

struct ShoppingScreen: View {
    
    @ObservedObject private var model: ShoppingModel = ShoppingModel()
    
    init() {
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(model.items) { item in
                    Text(item.title)
                }
                .onDelete(perform: model.deleteItems)
            }
            .toolbar {
                //#if os(iOS)
                //EditButton()
                //#endif

                Button(action: model.addItem) {
                    Label("Add Item", systemImage: "plus")
                }
            }.navigationTitle("Shopping lists")
        }
        
    }
}

struct ShoppingScreen_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingScreen()
    }
}
