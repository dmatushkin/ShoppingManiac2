//
//  AddGoodView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI

struct AddGoodView: View {
    
    let model: GoodsModel
    @State private var name: String = ""
    @State private var category: String = ""
    
    var body: some View {
        VStack {
            TextField("Good name", text: $name).textFieldStyle(.roundedBorder)
            TextField("Category name", text: $category).textFieldStyle(.roundedBorder)
            Button("Add", action: {
                Task {
                    try await model.addGood(name: name, category: category)
                }
            }).padding([.top])
            Spacer()
        }.padding().background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
    }
}
