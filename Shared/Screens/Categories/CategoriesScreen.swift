//
//  CategoriesScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI

struct CategoriesScreen: View {
    
    @StateObject private var model = CategoriesModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(model.items) { item in
                    NavigationLink(destination: {
                        NavigationLazyView(EditCategoryView(model: model, item: item))
                    }, label: {
                        Text(item.name)
                    })
                }.onDelete(perform: {indexSet in
                    Task {
                        try await model.removeStore(offsets: indexSet)
                    }
                })
            }.background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
                .toolbar {
                    Button(action: {
                        model.showAddSheet = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }.navigationTitle("Categories")
        }.sheet(isPresented: $model.showAddSheet, onDismiss: nil, content: {
            EditCategoryView(model: model, item: nil)
        })
    }
}

struct CategoriesScreen_Previews: PreviewProvider {
    static var previews: some View {
        CategoriesScreen()
    }
}
