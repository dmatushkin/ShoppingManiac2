//
//  GoodsScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI

struct GoodsScreen: View {
    
    @StateObject private var model = GoodsModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(model.items) { item in
                    NavigationLink(destination: {
                        NavigationLazyView(EditGoodView(model: model, item: item))
                    }, label: {
                        Text(item.name)
                    })
                }.onDelete(perform: {indexSet in
                    Task {
                        try await model.removeGood(offsets: indexSet)
                    }
                })
            }.background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
                .toolbar {
                    Button(action: {
                        model.showAddSheet = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }.navigationTitle("Goods")
        }.sheet(isPresented: $model.showAddSheet, onDismiss: nil, content: {
            EditGoodView(model: model, item: nil)
        })
    }
}

struct GoodsScreen_Previews: PreviewProvider {
    static var previews: some View {
        GoodsScreen()
    }
}
