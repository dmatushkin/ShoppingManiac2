//
//  AddCategoryView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI

struct AddCategoryView: View {
    
    let model: CategoriesModel
    @State private var name: String = ""
    
    var body: some View {
        VStack {
            TextField("Category name", text: $name).textFieldStyle(.roundedBorder)
            Button("Add", action: {
                Task {
                    try await model.addCategory(name: name)
                }
            }).padding([.top])
            Spacer()
        }.padding().background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
    }
}
