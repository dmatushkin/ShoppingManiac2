//
//  EditGoodView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI

struct EditGoodView: View {
    
    let model: GoodsModel
    let item: GoodsItemModel?
    @State private var name: String = ""
    @State private var category: String = ""
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        VStack {
            TextField("Good name", text: $name).textFieldStyle(.roundedBorder)
            TextField("Category name", text: $category).textFieldStyle(.roundedBorder)
            Button(item == nil ? "Add" : "Save", action: {
                Task {
                    try await model.editGood(item: item, name: name, category: category)
                    presentation.wrappedValue.dismiss()
                }
            }).padding([.top])
            Spacer()
        }.padding()
            .background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
            .onAppear(perform: {
                name = item?.name ?? ""
                category = item?.category ?? ""
            }).navigationTitle("Edit good")
    }
}
